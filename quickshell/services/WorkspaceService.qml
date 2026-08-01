pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property bool hasWorkspaces: false
    property int activeWorkspace: 1
    property int totalWorkspaces: 0
    property var workspaces: []
    property var workspaceNames: []

    function switchTo(index) {
        switchProc.command = ["python3", Quickshell.env("HOME") + "/.config/quickshell/services/python/workspace_service.py", "switch", index.toString()]
        switchProc.running = true
    }

    Process {
        id: switchProc
    }

    Process {
        id: queryProc
        command: ["python3", Quickshell.env("HOME") + "/.config/quickshell/services/python/workspace_service.py"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                try {
                    let parsed = JSON.parse(data.trim())
                    if (parsed && typeof parsed === "object") {
                        root.hasWorkspaces = parsed.hasWorkspaces === true && parsed.totalWorkspaces > 0
                        root.activeWorkspace = parsed.activeWorkspace || 1
                        root.totalWorkspaces = parsed.totalWorkspaces || 0
                        root.workspaces = parsed.workspaces || []
                        
                        let names = []
                        if (Array.isArray(parsed.workspaces)) {
                            for (let i = 0; i < parsed.workspaces.length; i++) {
                                names.push(parsed.workspaces[i].name)
                            }
                        }
                        root.workspaceNames = names
                    }
                } catch (e) {
                    root.hasWorkspaces = false
                }
            }
        }
    }

    Timer {
        interval: 400
        running: true
        repeat: true
        onTriggered: {
            if (!queryProc.running) queryProc.running = true
        }
    }
}
