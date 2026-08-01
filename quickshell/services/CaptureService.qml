import QtQuick
import Quickshell
import Quickshell.Io

pragma Singleton

Item {
    id: root

    Process {
        id: execProc
    }

    function captureRegion() {
        PopupService.closeAll()
        execProc.command = ["spectacle", "-r"]
        execProc.running = true
    }

    function captureFullscreen() {
        PopupService.closeAll()
        execProc.command = ["spectacle", "-f", "-b", "-c"]
        execProc.running = true
    }

    function captureWindow() {
        PopupService.closeAll()
        execProc.command = ["spectacle", "-a", "-b", "-c"]
        execProc.running = true
    }

    function recordRegion() {
        PopupService.closeAll()
        execProc.command = ["spectacle", "-R", "r"]
        execProc.running = true
    }

    function recordScreen() {
        PopupService.closeAll()
        execProc.command = ["spectacle", "-R", "s"]
        execProc.running = true
    }

    function openGui() {
        PopupService.closeAll()
        execProc.command = ["spectacle", "-g"]
        execProc.running = true
    }
}
