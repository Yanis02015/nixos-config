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
RowLayout {
    id: root
    spacing: Globals.spacing

    function iconSource(appId) {
        const entry = DesktopEntries.byId(appId) || DesktopEntries.heuristicLookup(appId);
        const themeName = (entry && entry.icon) ? entry.icon : appId;
        return Quickshell.iconPath(themeName, "application-x-executable");
    }

    Repeater {
        model: ToplevelManager.toplevels

        delegate: Item {
            id: win
            required property var modelData

            implicitWidth: Globals.barIconSize
            implicitHeight: Globals.barIconSize + 6 // room for the active-dot underneath
            Layout.alignment: Qt.AlignVCenter

            Image {
                id: content
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                width: Globals.barIconSize
                height: Globals.barIconSize
                source: root.iconSource(win.modelData.appId)
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
                visible: win.modelData.activated
            }

            MouseArea {
                id: ma
                anchors.fill: content
                anchors.margins: -2
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: win.modelData.activate()
            }
        }
    }
}
