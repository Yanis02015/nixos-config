pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.templates

// Quick-launch icons for pinned apps -> click to spawn, list is meant to grow over time.
// Icons are resolved from the system icon theme (same lookup the app launcher uses),
// so `icon` must match a .desktop file's Icon= key, not a glyph.
RowLayout {
    id: root
    spacing: Globals.spacing

    // add new pins here: { icon: "<icon-theme name, from the app's .desktop Icon= key>", command: ["binary", "args"...] }
    property var pins: [
        {
            icon: "discord",
            command: ["discord"]
        },
        {
            icon: "zed",
            command: ["zeditor"]
        }
    ]

    Repeater {
        model: root.pins
        delegate: Item {
            id: pin
            required property var modelData

            implicitWidth: Globals.barIconSize
            implicitHeight: Globals.barIconSize

            Image {
                id: content
                anchors.fill: parent
                source: Quickshell.iconPath(pin.modelData.icon, "")
                fillMode: Image.PreserveAspectFit
                smooth: true
                opacity: ma.containsMouse ? 0.75 : 1
            }

            MouseArea {
                id: ma
                anchors.fill: parent
                anchors.margins: -2
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: launchProc.running = true
            }

            Process {
                id: launchProc
                command: pin.modelData.command
            }
        }
    }
}
