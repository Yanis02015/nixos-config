pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import qs.templates
import qs.menus.launcher
import "Fuzzy.js" as Fuzzy

import QtQuick
import QtQuick.Layouts

// Clipboard history panel.
// Data comes from `cliphist` (wl-paste --watch cliphist store is already running).
//   cliphist list           -> "<id>\t<preview>" per line ([[ binary data ... ]] for images)
//   cliphist decode <id>    -> full text (stdout) or raw image bytes
//   cliphist wipe           -> clear all
// Typing filters the list with fzf-style fuzzy matching on the cliphist preview
// line (Fuzzy.js); matched characters are highlighted, ties keep recency order.
// Pinned entries (Ctrl/Alt+P or the pin icon, like Maccy) live outside cliphist
// in pinDir - one raw file per pin + pins.json - so they survive "Clear all" and
// cliphist's max-items pruning. They stay on top, and the history hides entries
// whose preview matches a pin so a pinned item isn't listed twice.
// Ctrl+Delete removes the selected entry for good: from cliphist for history,
// and for a pin both its stored copy and any hidden cliphist duplicates.
// Styling mirrors the notification center; window chrome comes from PopupWindow.

Scope {
    id: root

    // local open state, toggled via IPC (mirrors Notifications' centerOpen)
    property bool clipboardOpen: false

    // drives both the highlight and the preview pane
    property int selectedIndex: 0

    // full history from `cliphist list` (newest first); clipModel holds the filtered view
    property var entries: []
    property string query: ""

    // pinned entries, in pin order: { file, preview, isImage }
    property var pins: []
    readonly property string pinDir: (Quickshell.env("XDG_DATA_HOME") || Quickshell.env("HOME") + "/.local/share") + "/quickshell/clipboard-pins"
    readonly property string pinIndex: pinDir + "/pins.json"
    property var pendingPin: null // pin being snapshotted by pinProc
    readonly property bool hasAny: entries.length > 0 || pins.length > 0

    // ----- sizing -----
    readonly property int listWidth: 300                              // left list / truncation width
    readonly property int previewWidth: Math.round(listWidth * 1.5)   // right preview pane, 1.5x the list
    readonly property int bodyHeight: 460                             // fixed height for both columns

    // ----- preview state -----
    property string hoveredKey: ""
    property bool previewIsImage: false
    property string previewText: ""
    property string previewImage: ""
    property string pendingImgPath: ""

    function imgPathFor(id: string): string {
        return "/tmp/qs-clip-preview-" + id + ".img";
    }

    function pinPath(file: string): string {
        return root.pinDir + "/" + file;
    }

    function refresh(): void {
        listProc.running = true;
    }

    // fuzzy-rank one source list; an empty query keeps its original order
    function rank(list, tokens) {
        let scored = [];
        for (let i = 0; i < list.length; i++) {
            const e = list[i];
            const m = tokens.length ? Fuzzy.match(e.preview.toLowerCase(), tokens) : {
                score: 0,
                positions: []
            };
            if (!m)
                continue;
            scored.push({
                e: e,
                i: i,
                score: m.score,
                positions: m.positions
            });
        }
        scored.sort((a, b) => b.score !== a.score ? b.score - a.score : a.i - b.i);
        return scored;
    }

    // rebuild the visible list: pins first, then the history (minus pinned
    // duplicates); keepPreview re-selects that entry (pin <-> history keep the
    // same preview) so toggling a pin doesn't jump the selection back to the top
    function rebuild(keepPreview: string): void {
        const q = root.query.trim().toLowerCase();
        const tokens = q.length ? q.split(/\s+/) : [];
        const hl = String(Globals.fgColor2);
        const pinned = new Set(root.pins.map(p => p.preview));
        const history = root.entries.filter(e => !pinned.has(e.preview));

        clipModel.clear();
        for (const s of root.rank(root.pins, tokens))
            clipModel.append({
                key: "pin:" + s.e.file,
                cid: "",
                file: s.e.file,
                pinned: true,
                isImage: s.e.isImage,
                preview: s.e.preview,
                label: Fuzzy.highlight(s.e.preview, s.positions, hl)
            });
        for (const s of root.rank(history, tokens))
            clipModel.append({
                key: "clip:" + s.e.cid,
                cid: s.e.cid,
                file: "",
                pinned: false,
                isImage: s.e.isImage,
                preview: s.e.preview,
                label: Fuzzy.highlight(s.e.preview, s.positions, hl)
            });

        // select + preview the kept entry, else the best match (or the most recent entry)
        let idx = 0;
        if (keepPreview) {
            for (let i = 0; i < clipModel.count; i++) {
                if (clipModel.get(i).preview === keepPreview) {
                    idx = i;
                    break;
                }
            }
        }
        root.selectedIndex = idx;
        if (clipModel.count > 0)
            root.select(idx);
        else
            root.clearPreview();
    }

    // load the full content of an entry into the preview pane on hover
    function loadPreview(it): void {
        root.hoveredKey = it.key;
        root.previewIsImage = it.isImage;
        if (it.isImage) {
            root.previewText = "";
            root.previewImage = "";
            if (it.pinned) {
                imgDecodeProc.running = false;
                root.previewImage = "file://" + root.pinPath(it.file);
                return;
            }
            root.pendingImgPath = root.imgPathFor(it.cid);
            imgDecodeProc.running = false;
            imgDecodeProc.command = ["sh", "-c", "cliphist decode " + it.cid + " > " + root.pendingImgPath];
            imgDecodeProc.running = true;
        } else {
            root.previewImage = "";
            textDecodeProc.running = false;
            textDecodeProc.command = it.pinned ? ["cat", root.pinPath(it.file)] : ["cliphist", "decode", it.cid];
            textDecodeProc.running = true;
        }
    }

    function copyItem(it): void {
        copyProc.command = it.pinned ? ["sh", "-c", "wl-copy < \"$1\"", "_", root.pinPath(it.file)] : ["sh", "-c", "cliphist decode " + it.cid + " | wl-copy"];
        copyProc.running = true;
    }

    // ----- pins -----

    function savePins(): void {
        pinFile.setText(JSON.stringify(root.pins, null, 2) + "\n");
    }

    function togglePinAt(index: int): void {
        if (index < 0 || index >= clipModel.count || pinProc.running)
            return;
        const it = clipModel.get(index);
        if (it.pinned) {
            root.pins = root.pins.filter(p => p.file !== it.file);
            root.savePins();
            unpinProc.command = ["rm", "-f", root.pinPath(it.file)];
            unpinProc.running = true;
            root.rebuild(it.preview);
            return;
        }
        // snapshot the raw bytes now: the cliphist entry may be pruned or wiped later
        root.pendingPin = {
            file: Date.now() + ".bin",
            preview: it.preview,
            isImage: it.isImage
        };
        pinProc.command = ["sh", "-c", "mkdir -p \"$1\" && cliphist decode \"$2\" > \"$1/$3\"", "_", root.pinDir, it.cid, root.pendingPin.file];
        pinProc.running = true;
    }

    // delete the entry at index; the selection moves to its neighbour (next,
    // else previous) so repeated Ctrl+Delete walks down the list
    function deleteAt(index: int): void {
        if (index < 0 || index >= clipModel.count || deleteProc.running || pinProc.running)
            return;
        const it = clipModel.get(index);
        const next = index + 1 < clipModel.count ? clipModel.get(index + 1).preview : (index > 0 ? clipModel.get(index - 1).preview : "");

        let ids = [];
        if (it.pinned) {
            ids = root.entries.filter(e => e.preview === it.preview).map(e => e.cid);
            root.pins = root.pins.filter(p => p.file !== it.file);
            root.savePins();
            unpinProc.command = ["rm", "-f", root.pinPath(it.file)];
            unpinProc.running = true;
        } else {
            ids = [it.cid];
        }
        if (ids.length) {
            deleteProc.command = ["sh", "-c", "printf '%s\\n' \"$@\" | cliphist delete", "_"].concat(ids);
            deleteProc.running = true;
            root.entries = root.entries.filter(e => !ids.includes(e.cid));
        }
        root.rebuild(next);
    }

    // ----- selection (single source of truth, mirrors the launcher) -----

    // set the active row + load its preview; the hoveredKey guard dedupes the
    // stream of hover events so we only re-decode when the row actually changes
    function select(index: int): void {
        if (index < 0 || index >= clipModel.count)
            return;
        root.selectedIndex = index;
        const it = clipModel.get(index);
        if (it.key !== root.hoveredKey)
            root.loadPreview(it);
    }

    function moveSel(delta: int): void {
        const n = clipModel.count;
        if (n === 0)
            return;
        root.select((root.selectedIndex + delta + n) % n);
    }

    function activateAt(index: int): void {
        if (index < 0 || index >= clipModel.count)
            return;
        root.copyItem(clipModel.get(index));
        root.clipboardOpen = false;
    }

    // PopupWindow forwards every keypress here; an unaccepted Escape (and an
    // outside click) is left to PopupWindow, which closes the panel
    function handleKey(event): void {
        const k = event.key;
        if (k === Qt.Key_Escape) {
            // first Escape clears a non-empty query; an empty query is left
            // unaccepted so PopupWindow closes the panel
            if (root.query.length > 0) {
                root.query = "";
                event.accepted = true;
            }
            return;
        }
        // Ctrl+P / Alt+P (Maccy's Option+P) pins or unpins the selected entry;
        // checked before the printable branch since Alt+P still carries a "p"
        if (k === Qt.Key_P && (event.modifiers & (Qt.ControlModifier | Qt.AltModifier))) {
            root.togglePinAt(root.selectedIndex);
            event.accepted = true;
            return;
        }
        if (k === Qt.Key_Delete && (event.modifiers & Qt.ControlModifier)) {
            root.deleteAt(root.selectedIndex);
            event.accepted = true;
            return;
        }
        if (k === Qt.Key_Down || (k === Qt.Key_Tab && !(event.modifiers & Qt.ShiftModifier))) {
            root.moveSel(1);
            event.accepted = true;
            return;
        }
        if (k === Qt.Key_Up || k === Qt.Key_Backtab || (k === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier))) {
            root.moveSel(-1);
            event.accepted = true;
            return;
        }
        if (k === Qt.Key_Return || k === Qt.Key_Enter) {
            root.activateAt(root.selectedIndex);
            event.accepted = true;
            return;
        }
        if (k === Qt.Key_Backspace) {
            root.query = root.query.slice(0, -1);
            event.accepted = true;
            return;
        }
        // printable characters extend the query
        if (event.text && event.text.length === 1 && event.text.charCodeAt(0) >= 0x20) {
            root.query += event.text;
            event.accepted = true;
        }
    }

    function clearPreview(): void {
        root.hoveredKey = "";
        root.previewText = "";
        root.previewImage = "";
        root.previewIsImage = false;
    }

    onQueryChanged: rebuild("")

    // refresh list + reset query/preview/selection whenever the panel opens
    onClipboardOpenChanged: {
        if (clipboardOpen) {
            query = "";
            selectedIndex = 0;
            clearPreview();
            refresh();
        }
    }

    // ----- backend model -----
    ListModel {
        id: clipModel
    }

    Process {
        id: listProc
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                let out = [];
                const lines = text.split("\n");

                for (const line of lines) {
                    if (line.trim() === "")
                        continue;
                    const tab = line.indexOf("\t");
                    if (tab < 0)
                        continue;

                    const id = line.substring(0, tab);
                    const prev = line.substring(tab + 1);
                    const isImg = prev.startsWith("[[ binary data");
                    // turn "[[ binary data 2 MiB png 1920x2160 ]]" into a tidy label
                    const label = isImg ? "Image · " + prev.replace("[[ binary data ", "").replace(" ]]", "") : prev;
                    out.push({
                        cid: id,
                        preview: label,
                        isImage: isImg
                    });
                }
                root.entries = out;
                root.rebuild("");
            }
        }
    }

    // pins.json is read once at startup; afterwards root.pins is the source of truth
    Process {
        id: pinLoadProc
        command: ["cat", root.pinIndex]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const list = JSON.parse(text);
                    if (Array.isArray(list))
                        root.pins = list;
                } catch (e) {}
            }
        }
    }

    FileView {
        id: pinFile
        path: root.pinIndex
        atomicWrites: true
        printErrors: false
    }

    Component.onCompleted: pinLoadProc.running = true

    Process {
        id: pinProc
        onExited: (exitCode, exitStatus) => {
            const p = root.pendingPin;
            root.pendingPin = null;
            if (exitCode !== 0 || !p)
                return;
            root.pins = root.pins.concat([p]);
            root.savePins();
            root.rebuild(p.preview);
        }
    }

    Process {
        id: unpinProc
    }

    Process {
        id: deleteProc
    }

    Process {
        id: textDecodeProc
        stdout: StdioCollector {
            onStreamFinished: root.previewText = text
        }
    }

    Process {
        id: imgDecodeProc
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0)
                root.previewImage = "file://" + root.pendingImgPath;
        }
    }

    Process {
        id: copyProc
    }

    // pins live outside cliphist, so "Clear all" leaves them in place
    Process {
        id: wipeProc
        command: ["cliphist", "wipe"]
        onExited: {
            root.clearPreview();
            root.refresh();
        }
    }

    IpcHandler {
        target: "clipboard"
        function toggle(): void {
            root.clipboardOpen = !root.clipboardOpen;
        }
        function show(): void {
            root.clipboardOpen = true;
        }
        function hide(): void {
            root.clipboardOpen = false;
        }
    }

    // PopupWindow provides the full-screen catcher, keyboard focus + close-on-keypress
    PopupWindow {
        open: root.clipboardOpen
        onDismissed: root.clipboardOpen = false
        onKeyDown: event => root.handleKey(event)

        margins {
            top: Globals.marginsTop + (Globals.barShown ? Globals.currentBarHeight + Globals.hyprGaps : 0)
            left: Globals.marginsLeft
        }

        ColumnLayout {
            id: col
            spacing: Globals.spacing + 2

            // ---- header ----
            RowLayout {
                Layout.fillWidth: true
                // nudge the heading + clear button inward off the panel edges
                Layout.leftMargin: Globals.spacing
                Layout.rightMargin: Globals.spacing
                spacing: Globals.spacing

                Text {
                    text: String.fromCodePoint(0xF014D) // nf-md-clipboard_text 󰅍
                    visible: Globals.headerIcons
                    color: Globals.fgColor
                    font.family: Globals.textFont.family
                    font.pixelSize: Globals.textFont.pixelSize + 6
                    font.weight: Globals.textFont.weight
                }

                Text {
                    Layout.fillWidth: true
                    text: "Clipboard"
                    color: Globals.fgColor
                    font.family: Globals.textFont.family
                    font.pixelSize: Globals.textFont.pixelSize + 2
                    font.weight: Globals.textFont.weight
                }

                Text {
                    text: "Clear all"
                    visible: root.entries.length > 0
                    color: Globals.criticalColor
                    font.family: Globals.textFont.family
                    font.weight: Globals.textFont.weight
                    font.pixelSize: Globals.textFont.pixelSize - 1

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -1
                        cursorShape: Qt.PointingHandCursor
                        onClicked: wipeProc.running = true
                    }
                }
            }

            MenuDivider {
                Layout.leftMargin: Globals.spacing
                Layout.rightMargin: Globals.spacing
            }

            // ---- search (fuzzy filter, typed straight into the panel) ----
            SearchInput {
                visible: root.hasAny
                Layout.fillWidth: true
                query: root.query
                placeholder: "Search clipboard…"
                active: root.clipboardOpen
            }

            MenuDivider {
                visible: root.hasAny
                Layout.leftMargin: Globals.spacing
                Layout.rightMargin: Globals.spacing
            }

            // empty state - keeps the list column's width (no preview pane) so the panel doesn't shrink horizontally when there's no history
            Text {
                visible: !root.hasAny
                Layout.preferredWidth: root.listWidth
                text: "No clipboard history"
                color: Qt.alpha(Globals.fgColor, 0.4)
                font.family: Globals.textFont.family
                font.pixelSize: Globals.textFont.pixelSize - 1
                horizontalAlignment: Text.AlignHCenter
            }

            // ---- body: list (left) + preview (right) ----
            // only present when there is history; otherwise the second column doesn't exist
            RowLayout {
                visible: root.hasAny
                Layout.fillWidth: true
                spacing: Globals.spacing + 2

                // left: scrollable entry list (selection model mirrors the launcher's
                // ResultList - selectedIndex is the single source of truth)
                ListView {
                    id: listView
                    Layout.preferredWidth: root.listWidth
                    Layout.preferredHeight: root.bodyHeight
                    model: clipModel
                    currentIndex: root.selectedIndex
                    highlightFollowsCurrentItem: false
                    boundsBehavior: Flickable.StopAtBounds
                    clip: true
                    cacheBuffer: 200
                    pixelAligned: true
                    spacing: Globals.spacing

                    // nothing matches the query - same muted style as the empty state
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: Globals.spacing
                        visible: clipModel.count === 0
                        text: "No matches"
                        color: Qt.alpha(Globals.fgColor, 0.4)
                        font.family: Globals.textFont.family
                        font.pixelSize: Globals.textFont.pixelSize - 1
                    }

                    // keep the keyboard-selected row scrolled into view
                    onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

                    // bigger, smoother wheel step than the default (same as the launcher)
                    WheelHandler {
                        property real scrollSpeed: 2
                        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                        onWheel: event => {
                            const maxY = Math.max(0, listView.contentHeight - listView.height);
                            listView.contentY = Math.max(0, Math.min(maxY, listView.contentY - event.angleDelta.y * scrollSpeed));
                        }
                    }

                    delegate: Rectangle {
                        id: entry
                        required property string cid
                        required property string label
                        required property bool pinned
                        required property bool isImage
                        required property int index

                        readonly property bool sel: root.selectedIndex === entry.index

                        width: ListView.view.width
                        implicitHeight: entryText.implicitHeight + (Globals.spacing + 2) * 2
                        radius: Globals.radius

                        // faint tint on the active entry (matches the launcher list)
                        color: entry.sel ? Qt.alpha(Globals.fgColor, 0.15) : "transparent"

                        Behavior on color {
                            ColorAnimation {
                                duration: Globals.animFast
                            }
                        }

                        // short colour bar on the left edge of the active entry; fades
                        // with the same timing as the row tint so the two move together
                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            anchors.topMargin: Globals.spacing
                            anchors.bottomMargin: Globals.spacing
                            width: 3
                            radius: 2
                            color: Globals.fgColor
                            opacity: entry.sel ? 1 : 0
                            Behavior on opacity {
                                NumberAnimation {
                                    duration: Globals.animFast
                                }
                            }
                        }

                        Text {
                            id: entryText
                            anchors {
                                left: parent.left
                                right: parent.right
                                verticalCenter: parent.verticalCenter
                                leftMargin: Globals.spacing + 8
                                rightMargin: Globals.spacing + 2 + pinIcon.width + Globals.spacing
                            }
                            text: entry.label
                            textFormat: Text.StyledText
                            color: Globals.fgColor
                            font.family: Globals.textFont.family
                            font.pixelSize: Globals.textFont.pixelSize - 1
                            elide: Text.ElideRight
                            maximumLineCount: 1
                        }

                        MouseArea {
                            id: ema
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onPositionChanged: root.select(entry.index)
                            onClicked: root.activateAt(entry.index)
                        }

                        // pin toggle: always shown on pinned entries, on hover/selection
                        // otherwise; sits above the row MouseArea so its click wins
                        Text {
                            id: pinIcon
                            anchors.right: parent.right
                            anchors.rightMargin: Globals.spacing + 2
                            anchors.verticalCenter: parent.verticalCenter
                            text: String.fromCodePoint(0xF0403) // nf-md-pin 󰐃
                            color: entry.pinned ? Globals.fgColor2 : Globals.fgColor
                            opacity: entry.pinned ? 1 : (pinMa.containsMouse ? 0.9 : (entry.sel || ema.containsMouse ? 0.35 : 0))
                            font.family: Globals.textFont.family
                            font.pixelSize: Globals.textFont.pixelSize
                            Behavior on opacity {
                                NumberAnimation {
                                    duration: Globals.animFast
                                }
                            }

                            MouseArea {
                                id: pinMa
                                anchors.fill: parent
                                anchors.margins: -4
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.togglePinAt(entry.index)
                            }
                        }
                    }
                }

                // thin divider between list and preview (equal top/bottom gaps)
                Rectangle {
                    Layout.preferredWidth: Globals.borderWidth === 0 ? 1 : Globals.borderWidth // keeps the divider regardless of if we go no borders or not
                    Layout.preferredHeight: root.bodyHeight - Globals.padding * 2
                    Layout.alignment: Qt.AlignVCenter
                    Layout.leftMargin: Globals.spacing
                    color: Qt.alpha(Globals.fgColor, 0.3)
                }

                // right: fixed-width preview of the hovered entry
                Item {
                    Layout.preferredWidth: root.previewWidth
                    Layout.preferredHeight: root.bodyHeight
                    clip: true

                    // image preview
                    Image {
                        anchors.fill: parent
                        anchors.margins: Globals.spacing
                        visible: root.previewIsImage && root.previewImage !== ""
                        source: root.previewImage
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                        cache: false
                    }

                    // text preview - starts top-left and reads down like a book
                    Text {
                        anchors {
                            top: parent.top
                            left: parent.left
                            right: parent.right
                            margins: Globals.spacing
                        }
                        visible: !root.previewIsImage && root.hoveredId !== ""
                        text: root.previewText
                        color: Globals.fgColor
                        font.family: Globals.textFont.family
                        font.pixelSize: Globals.textFont.pixelSize - 1
                        horizontalAlignment: Text.AlignLeft
                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    }
                }
            }
        }
    }
}
