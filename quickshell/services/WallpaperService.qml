pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../theme"

Item {
    id: root

    property var wallpapers: []
    property string activeCustomWallpaper: ""

    // Automatic recolor watcher background daemon
    Process {
        id: watcherProc
        command: ["python3", "/home/sho/Documents/themes/quickshell/services/python/recolor_watcher.py"]
        running: true
    }

    // High-speed Python scanner process for ~/Pictures/Wallpapers per-theme variant subfolders
    Process {
        id: scanProc
        command: ["python3", "/home/sho/Documents/themes/quickshell/services/python/wallpaper_scanner.py"]
        stdout: SplitParser {
            onRead: data => {
                try {
                    let parsed = JSON.parse(data.trim())
                    if (parsed && Array.isArray(parsed)) {
                        root.wallpapers = parsed
                    }
                } catch (e) {}
            }
        }
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        onTriggered: {
            if (!scanProc.running) scanProc.running = true
        }
    }

    Component.onCompleted: {
        scanProc.running = true
    }

    function applyWallpaper(filePath) {
        if (!filePath) return;
        activeCustomWallpaper = filePath
        let fileUrl = filePath.startsWith("file://") ? filePath : "file://" + filePath
        Theme.wallpaperPath = fileUrl
        let rawPath = filePath.replace("file://", "")
        Quickshell.execDetached(["plasma-apply-wallpaperimage", rawPath])
    }

    function refresh() {
        if (!scanProc.running) scanProc.running = true
    }
}
