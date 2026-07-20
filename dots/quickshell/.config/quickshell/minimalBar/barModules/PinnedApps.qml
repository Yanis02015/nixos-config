pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.templates

// Quick-launch icons for pinned apps -> click to spawn, list is meant to grow over time.
// Each pin resolves its icon one of two ways:
//   - `icon: "<name>"`  -> looked up in the system icon theme (.desktop Icon= key), same as the launcher
//   - `asset: "assets/<file>"` -> bundled file next to this component, for logos that need a specific
//     rendering (e.g. a mark that's illegible at icon-theme sizes, or has no theme icon at all)
// `size` is optional -> overrides Globals.barIconSize for pins whose mark needs more room to stay legible
// (Zed's nested-line logo turns into a blob below ~22px, unlike Discord's bolder mark).
RowLayout {
    id: root
    spacing: Globals.spacing

    property var pins: [
        {
            icon: "discord",
            command: ["discord"]
        },
        {
            asset: "assets/zed.png",
            size: Globals.barIconSize + 8,
            command: ["zeditor"]
        }
    ]

    Repeater {
        model: root.pins
        delegate: Item {
            id: pin
            required property var modelData

            readonly property int iconSize: pin.modelData.size ?? Globals.barIconSize

            implicitWidth: pin.iconSize
            implicitHeight: pin.iconSize
            Layout.alignment: Qt.AlignVCenter

            Image {
                id: content
                anchors.fill: parent
                source: pin.modelData.asset ? Qt.resolvedUrl("../" + pin.modelData.asset) : Quickshell.iconPath(pin.modelData.icon, "")
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
