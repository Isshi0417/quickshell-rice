import QtQuick
import Quickshell
import Quickshell.Io

pragma Singleton

Item {
    id: root

    function captureRegion() {
        PopupService.closeAll()
        Quickshell.execDetached(["spectacle", "-r"])
    }

    function captureFullscreen() {
        PopupService.closeAll()
        Quickshell.execDetached(["spectacle", "-f", "-b", "-c"])
    }

    function captureWindow() {
        PopupService.closeAll()
        Quickshell.execDetached(["spectacle", "-a", "-b", "-c"])
    }

    function recordRegion() {
        PopupService.closeAll()
        Quickshell.execDetached(["spectacle", "-R", "r"])
    }

    function recordScreen() {
        PopupService.closeAll()
        Quickshell.execDetached(["spectacle", "-R", "s"])
    }

    function openGui() {
        PopupService.closeAll()
        Quickshell.execDetached(["spectacle", "-g"])
    }
}
