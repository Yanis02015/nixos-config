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
// Shows at most maxVisible icons; anything past that collapses into a "+N" badge whose hover
// reveals the rest in a HoverFlyout (floating, doesn't reflow the bar -> see templates/HoverFlyout.qml).
RowLayout {
    id: root
    spacing: Globals.spacing

    // same monitor as the enclosing bar instance -> set from shell.qml (Variants model: Quickshell.screens)
    property var screen: null

    readonly property int maxVisible: 4
    readonly property var allWindows: ToplevelManager.toplevels.values
    readonly property int overflowCount: Math.max(0, root.allWindows.length - root.maxVisible)

    function iconSource(appId) {
        const entry = DesktopEntries.byId(appId) || DesktopEntries.heuristicLookup(appId);
        const themeName = (entry && entry.icon) ? entry.icon : appId;
        return Quickshell.iconPath(themeName, "application-x-executable");
    }

    // small close delay so moving the mouse from the badge into the flyout doesn't flicker it shut
    Timer {
        id: closeTimer
        interval: 150
        onTriggered: flyout.open = false
    }
    function openFlyout() {
        closeTimer.stop();
        // computed on demand rather than bound reactively -> mapToItem() inside a binding doesn't
        // reliably re-evaluate once the RowLayout finishes positioning the badge after startup
        flyout.anchorCenterX = overflowBadge.mapToItem(null, overflowBadge.width / 2, 0).x;
        flyout.open = true;
    }
    function scheduleCloseFlyout() {
        closeTimer.restart();
    }

    component WindowIcon: Item {
        id: win
        required property var toplevel

        // matches the CPU/RAM/badge icons' own implicit height -> keeps every glyph on the same
        // vertical centre-line; the active-dot below is allowed to overflow this box rather than
        // reserving space for it (which would push the icon off-centre from its siblings)
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

    Repeater {
        model: root.allWindows.slice(0, root.maxVisible)
        delegate: WindowIcon {
            required property var modelData
            Layout.alignment: Qt.AlignVCenter
            toplevel: modelData
        }
    }

    Rectangle {
        id: overflowBadge
        visible: root.overflowCount > 0
        implicitWidth: badgeIcon.implicitWidth + Globals.horiPadding
        implicitHeight: badgeIcon.implicitHeight + Globals.vertPadding
        radius: implicitHeight / 2 // same pill treatment as BarRight's metrics island
        color: Globals.bgColor
        Layout.alignment: Qt.AlignVCenter

        // same glyph+value pattern as the CPU/RAM/battery icons in BarRight, now in a matching pill
        BarIcon {
            id: badgeIcon
            anchors.centerIn: parent
            icon: "󰐕" // nf-md-plus
            displayText: root.overflowCount.toString()
            color: Globals.fgColor
            opacity: ma.containsMouse ? 0.75 : 1
        }

        MouseArea {
            id: ma
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: root.openFlyout()
            onExited: root.scheduleCloseFlyout()
        }
    }

    HoverFlyout {
        id: flyout
        screen: root.screen

        Item {
            width: flyoutRow.implicitWidth
            height: flyoutRow.implicitHeight

            HoverHandler {
                onHoveredChanged: {
                    if (hovered)
                        root.openFlyout();
                    else
                        root.scheduleCloseFlyout();
                }
            }

            RowLayout {
                id: flyoutRow
                spacing: Globals.spacing

                Repeater {
                    model: root.allWindows.slice(root.maxVisible)
                    delegate: WindowIcon {
                        required property var modelData
                        toplevel: modelData
                    }
                }
            }
        }
    }
}
