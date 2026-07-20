pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.templates

// Icons for currently-open windows -> click to focus, not launch (Quickshell.Wayland.ToplevelManager,
// backed by the standard wlr-foreign-toplevel-management-v1 protocol -> updates itself on open/close,
// no polling). One icon per window (not grouped by app), across every workspace.
//
// appId is the Hyprland "class" -> not always an icon-theme name by itself, so it's resolved via
// DesktopEntries (same source Launcher.qml uses) to the app's real .desktop Icon= key -> works
// generically for any app, no per-app mapping.
//
// Shows at most maxVisible icons (the most recent ones, kept stable so hovering never reorders
// what's already on screen). Hovering the row reveals the rest prepended on the LEFT -> this module
// is right-anchored against the metrics island (see shell.qml), so growing leftward keeps that
// anchor point still instead of shoving the metrics island further right on every hover.
RowLayout {
    id: root
    spacing: Globals.spacing

    // taller than the icons themselves, matching the full bar strip -> without this the hoverable
    // area was only as tall as the icon glyphs (~barIconSize), so a few px up/down dropped the hover
    // and collapsed the reveal. Children stay centred on the same spot via Layout.alignment below.
    implicitHeight: Globals.currentBarHeight

    readonly property int maxVisible: 4

    // the active window must always land in the always-visible suffix (never hidden behind the
    // collapsed overflow group) -> move it to the end of the list, but only when it isn't already
    // within the trailing maxVisible slice, so focusing an already-visible window never reshuffles
    // the row
    readonly property var allWindows: {
        const list = ToplevelManager.toplevels.values;
        const activeIdx = list.findIndex(w => w.activated);
        if (activeIdx === -1 || activeIdx >= list.length - root.maxVisible)
            return list;
        const reordered = list.slice();
        const [active] = reordered.splice(activeIdx, 1);
        reordered.push(active);
        return reordered;
    }
    readonly property int overflowCount: Math.max(0, root.allWindows.length - root.maxVisible)

    function iconSource(appId) {
        const entry = DesktopEntries.byId(appId) || DesktopEntries.heuristicLookup(appId);
        const themeName = (entry && entry.icon) ? entry.icon : appId;
        return Quickshell.iconPath(themeName, "application-x-executable");
    }

    component WindowIcon: Item {
        id: win
        required property var toplevel

        // matches the CPU/RAM icons' own implicit height -> keeps every glyph on the same vertical
        // centre-line; the active-dot below is allowed to overflow this box rather than reserving
        // space for it (which would push the icon off-centre from its siblings)
        implicitWidth: Globals.barIconSize
        implicitHeight: Globals.barIconSize

        Image {
            id: content
            anchors.centerIn: parent
            width: Globals.barIconSize
            height: Globals.barIconSize
            source: root.iconSource(win.toplevel.appId)
            fillMode: Image.PreserveAspectFit
            smooth: true
            opacity: ma.containsMouse ? 0.75 : 1
        }

        // active-window indicator -> same dot pattern as Workspaces.qml's active workspace
        Rectangle {
            width: 4
            height: 4
            radius: 2
            anchors.top: content.bottom
            anchors.topMargin: 2
            anchors.horizontalCenter: parent.horizontalCenter
            color: Globals.fgColor
            visible: win.toplevel.activated
        }

        MouseArea {
            id: ma
            anchors.fill: content
            anchors.margins: -2
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: win.toplevel.activate()
        }
    }

    // passive hover tracking over the whole row -> a MouseArea here would sit on top of the icons
    // and eat their clicks before they arrive; HoverHandler never grabs the press event
    HoverHandler {
        id: rowHover
    }

    // overflow icons -> prepended before the always-visible ones, revealed with a width+fade
    // animation on hover instead of an instant model swap. The group stays in the model at all
    // times (so it animates) but drops out of the layout entirely -> visible: false -> when there's
    // nothing to show, so it costs no spacing when overflowCount is 0.
    Item {
        id: overflowGroup
        visible: root.overflowCount > 0
        Layout.preferredWidth: rowHover.hovered ? overflowRow.implicitWidth : 0
        Layout.preferredHeight: Globals.barIconSize
        Layout.alignment: Qt.AlignVCenter
        clip: true
        opacity: rowHover.hovered ? 1 : 0

        Behavior on Layout.preferredWidth {
            NumberAnimation {
                duration: Globals.animDuration
                easing.type: Easing.OutCubic
            }
        }
        Behavior on opacity {
            NumberAnimation {
                duration: Globals.animDuration
            }
        }

        RowLayout {
            id: overflowRow
            spacing: Globals.spacing

            Repeater {
                model: root.allWindows.slice(0, root.overflowCount)
                delegate: WindowIcon {
                    required property var modelData
                    toplevel: modelData
                }
            }
        }
    }

    // always-visible icons -> a stable suffix of the window list, never reordered by hovering
    Repeater {
        model: root.allWindows.slice(root.overflowCount)
        delegate: WindowIcon {
            required property var modelData
            Layout.alignment: Qt.AlignVCenter
            toplevel: modelData
        }
    }
}
