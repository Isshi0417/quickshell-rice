import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import "../../theme"
import "../../services"

PanelWindow {
    id: lockscreenWindow

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    WlrLayershell.layer: WlrLayershell.Overlay
    WlrLayershell.keyboardFocus: LockscreenService.isLocked ? WlrLayershell.Exclusive : WlrLayershell.None
    exclusionMode: ExclusionMode.Ignore

    visible: LockscreenService.isLocked
    color: Theme.bg

    // Raw System Wallpaper Image
    Image {
        id: bgImage
        anchors.fill: parent
        source: Theme.wallpaperPath
        fillMode: Image.PreserveAspectCrop

        Behavior on source {
            PropertyAnimation { duration: 300 }
        }
    }

    // Blurred Background of the current system wallpaper
    MultiEffect {
        anchors.fill: parent
        source: bgImage
        blurEnabled: true
        blur: 1.0
        blurMax: 64
        opacity: 0.85
    }

    // Glass Dark Backdrop Overlay with Gradient
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: Theme.isDark ? Qt.rgba(15/255, 15/255, 25/255, 0.45) : Qt.rgba(20/255, 20/255, 30/255, 0.35) }
            GradientStop { position: 0.5; color: Theme.isDark ? Qt.rgba(20/255, 20/255, 32/255, 0.55) : Qt.rgba(25/255, 25/255, 38/255, 0.45) }
            GradientStop { position: 1.0; color: Theme.isDark ? Qt.rgba(10/255, 10/255, 18/255, 0.65) : Qt.rgba(15/255, 15/255, 25/255, 0.55) }
        }
    }

    // Lockscreen Content Layout
    LockscreenContent {
        anchors.fill: parent
    }
}
