pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import qs.templates

import QtQuick

// Lightweight, non-modal popup for hover-only reveals (unlike PopupWindow: no keyboard grab,
// no click-outside catcher -> the owner drives `open` from hover state and is responsible for
// debouncing it, e.g. a short close-delay timer so moving the mouse from the anchor into the
// flyout doesn't flicker it shut).
PanelWindow { // qmllint disable uncreatable-type
    id: root

    screen: Globals.focusedScreen

    property bool open: false
    // scene-x (within this window) of the anchor's centre -> the card centres under it
    property real anchorCenterX: 0

    default property alias content: contentHolder.data

    visible: open
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore // Wayland: don't reserve screen space
    WlrLayershell.layer: WlrLayer.Overlay

    anchors {
        top: true
        left: true
    }
    margins {
        top: Globals.marginsTop + Globals.currentBarHeight + Globals.hyprGaps
        left: Math.max(0, root.anchorCenterX - implicitWidth / 2)
    }

    implicitWidth: contentHolder.childrenRect.width + Globals.padding
    implicitHeight: contentHolder.childrenRect.height + Globals.padding

    Rectangle {
        anchors.fill: parent
        color: Globals.menuBg
        radius: Globals.radius
        border.width: Globals.borderWidth
        border.color: Globals.borderColor
    }

    Item {
        id: contentHolder
        x: Globals.padding / 2
        y: Globals.padding / 2
    }
}
