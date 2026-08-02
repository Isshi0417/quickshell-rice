import QtQuick
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
    color: "black"

    // Background System Wallpaper
    Image {
        anchors.fill: parent
        source: WallpaperService.currentWallpaper
        fillMode: Image.PreserveAspectCrop
        opacity: 0.65

        Behavior on source {
            PropertyAnimation { duration: 300 }
        }
    }

    // Glass Dark Backdrop Overlay with Gradient
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: Theme.isDark ? Qt.rgba(15/255, 15/255, 25/255, 0.82) : Qt.rgba(20/255, 20/255, 30/255, 0.70) }
            GradientStop { position: 0.5; color: Theme.isDark ? Qt.rgba(20/255, 20/255, 32/255, 0.88) : Qt.rgba(25/255, 25/255, 38/255, 0.78) }
            GradientStop { position: 1.0; color: Theme.isDark ? Qt.rgba(10/255, 10/255, 18/255, 0.92) : Qt.rgba(15/255, 15/255, 25/255, 0.85) }
        }
    }

    // Lockscreen Content Layout
    LockscreenContent {
        anchors.fill: parent
    }
}
