import Quickshell
import Quickshell.Wayland
import QtQuick
import "modules/topbar"
import "modules/dock"
import "modules/launcher"
import "modules/wallpaper"
import "modules/notifications"
import "modules/desktop"
import "services"

Scope {
    // Dynamic Theme Wallpaper (Layer: Background)
    WallpaperWindow {}

    // Desktop Plasmoid System Monitor (Layer: Bottom, Non-restricting)
    SystemWidget {}

    // Standalone Running Hamster Engine Widget (Layer: Bottom, Bottom-Left)
    HamsterWidget {}
    // Full-screen transparent dismiss overlay (Layer: Top)
    PanelWindow {
        id: dismissOverlay
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        visible: PopupService.anyOpen
        color: "transparent"

        WlrLayershell.layer: WlrLayershell.Top
        WlrLayershell.keyboardFocus: WlrLayershell.None

        MouseArea {
            anchors.fill: parent
            onClicked: PopupService.closeAll()
        }
    }

    // Top Bar Container Window (Layer: Top)
    PanelWindow {
        id: window
        anchors {
            top: true
            left: true
            right: true
        }
        margins {
            top: 10
            left: 10
            right: 10
        }

        WlrLayershell.layer: WlrLayershell.Top
        implicitHeight: 40
        color: "transparent"

        TopLeftBar {
            id: topLeftBar
            anchors.left: parent.left
            anchors.top: parent.top
        }

        TopCenterBar {
            id: topCenterBar
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
        }

        TopRightBar {
            id: topRightBar
            anchors.right: parent.right
            anchors.top: parent.top
        }
    }

    // Bottom Dock Container Window (Layer: Top)
    PanelWindow {
        id: dockWindow
        anchors {
            bottom: true
            left: true
            right: true
        }
        margins {
            bottom: 10
        }

        WlrLayershell.layer: WlrLayershell.Top
        implicitHeight: 56
        color: "transparent"

        BottomDock {
            id: bottomDock
            dockWindow: dockWindow
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
        }
    }

    // Backdrop Window: Catch clicks outside theme picker to dismiss
    PanelWindow {
        id: themePickerBackdrop
        anchors { top: true; bottom: true; left: true; right: true }
        WlrLayershell.layer: WlrLayershell.Top
        exclusionMode: ExclusionMode.Ignore
        visible: PopupService.themePickerOpen
        color: "transparent"

        MouseArea {
            anchors.fill: parent
            onClicked: PopupService.closeAll()
        }
    }

    // Theme Switcher Floating Overlay (Dedicated Window)
    PanelWindow {
        id: themePickerWindow
        anchors {
            bottom: true
            right: true
        }
        margins {
            bottom: 74
            right: Math.max(20, Math.round((dockWindow.width - bottomDock.implicitWidth) / 2))
        }

        WlrLayershell.layer: WlrLayershell.Top
        exclusionMode: ExclusionMode.Ignore
        visible: PopupService.themePickerOpen
        implicitWidth: 360
        implicitHeight: 300
        color: "transparent"

        ThemePicker {
            anchors.fill: parent
        }
    }

    // Application Launcher Overlay
    AppLauncher {}

    // Bottom-Right Notification Toast Overlay
    NotificationToast {}
}
