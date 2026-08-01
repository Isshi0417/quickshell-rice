pragma Singleton
import QtQuick
import Quickshell.Io

Item {
    id: root

    property var items: []

    Component.onCompleted: {
        scanClipboard()
    }

    function copyEntry(id) {
        var entry = items.find(i => i.id === id)
        if (!entry) return

        if (entry.type === "image") {
            copyProc.command = ["bash", "-c", "wl-copy --type image/png < " + entry.path]
        } else {
            copyProc.command = ["wl-copy", entry.content]
        }
        copyProc.running = true
    }

    function deleteEntry(id) {
        var arr = []
        for (var i = 0; i < items.length; i++) {
            if (items[i].id !== id) {
                arr.push(items[i])
            }
        }
        items = arr
    }

    function clearAll() {
        items = []
        copyProc.command = ["wl-copy", "--clear"]
        copyProc.running = true
    }

    function scanClipboard() {
        if (!copyProc.running) {
            scanProc.running = false
            scanProc.running = true
        }
    }

    Process { id: copyProc }

    Process {
        id: scanProc
        command: ["python3", Quickshell.env("HOME") + "/.config/quickshell/services/python/clipboard_service.py"]
        running: true
        stdout: SplitParser {
            onRead: data => root.handleData(data)
        }
    }

    function handleData(data) {
        if (!data) return
        let trimmed = data.trim()
        if (!trimmed) return

        let lines = trimmed.split("\n")
        let currentList = root.items ? root.items.slice() : []
        let changed = false

        for (let i = 0; i < lines.length; i++) {
            let line = lines[i].trim()
            if (!line) continue
            try {
                let parsed = JSON.parse(line)
                if (parsed && parsed.hash) {
                    let existingIdx = currentList.findIndex(item => item.hash === parsed.hash)

                    if (existingIdx !== -1) {
                        currentList.splice(existingIdx, 1)
                    }

                    let d = new Date()
                    let hours = d.getHours() < 10 ? "0" + d.getHours() : "" + d.getHours()
                    let mins = d.getMinutes() < 10 ? "0" + d.getMinutes() : "" + d.getMinutes()
                    parsed.id = parsed.hash + "_" + d.getTime() + "_" + Math.floor(Math.random() * 1000)
                    parsed.time = hours + ":" + mins

                    currentList.unshift(parsed)
                    if (currentList.length > 30) currentList.pop()
                    changed = true
                }
            } catch (e) {}
        }

        if (changed) {
            root.items = currentList
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: scanClipboard()
    }
}
