import Quickshell
import Quickshell.Wayland
import QtQuick
import "../../theme"

PanelWindow {
    id: wallpaperWindow
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    WlrLayershell.layer: WlrLayershell.Background
    WlrLayershell.keyboardFocus: WlrLayershell.None
    exclusionMode: ExclusionMode.Ignore
    color: Theme.bg

    Image {
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        source: Theme.wallpaperPath

        Behavior on opacity { NumberAnimation { duration: 300 } }
    }
}
