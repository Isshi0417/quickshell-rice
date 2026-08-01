import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../components"
import "../../services"
import "../../theme"

Item {
    id: root

    implicitWidth: dockGlass.implicitWidth
    implicitHeight: dockGlass.implicitHeight

    // Active Context Menu State
    property var contextTargetApp: null
    property int contextTargetX: 0

    GlassPanel {
        id: dockGlass
        implicitWidth: dockRow.implicitWidth + 24
        implicitHeight: 52
        anchors.centerIn: parent

        RowLayout {
            id: dockRow
            anchors.centerIn: parent
            spacing: 6

            property int activeDragIndex: -1
            property real activeDragXOffset: 0
            property int activeOffsetSpaces: Math.round(activeDragXOffset / 48.0)

            // 1. Distro Application Launcher Button
            Item {
                id: launcherBtn
                width: 42
                height: 42
                Layout.alignment: Qt.AlignVCenter

                property bool isHovered: launcherMouse.containsMouse

                // Subtle Hover Capsule Background
                Rectangle {
                    anchors.fill: parent
                    radius: 8
                    color: launcherBtn.isHovered ? Qt.rgba(255/255, 255/255, 255/255, 0.08) : "transparent"

                    Behavior on color { ColorAnimation { duration: 120 } }
                }

                // Distro / Cute Emoji Icon Container
                Item {
                    anchors.centerIn: parent
                    width: 26
                    height: 26
                    scale: launcherBtn.isHovered ? 1.15 : 1.0

                    Behavior on scale {
                        NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "🐹"
                        font.pixelSize: 20
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                // Launcher Mouse Area
                MouseArea {
                    id: launcherMouse
                    anchors.fill: parent
                    hoverEnabled: true

                    onClicked: {
                        TaskService.toggleLauncher()
                    }
                }

            }

            // 2. Left Vertical Separator Line
            Rectangle {
                width: 1
                height: 22
                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: 2
                Layout.rightMargin: 2
                color: Theme.separator
            }

            // Combined Unified Dock Items (Pinned Apps + Unpinned Running Apps)
            Repeater {
                id: dockRepeater
                model: TaskService.allDockApps

                Item {
                    id: dockItem
                    width: 42
                    height: 42
                    Layout.alignment: Qt.AlignVCenter

                    property string appId: modelData.appId

                    property bool isHovered: itemMouse.containsMouse
                    property bool isAppRunning: TaskService.isRunning(modelData.appId)
                    property bool isAppActive: TaskService.isActive(modelData.appId)
                    property bool isDraggingThis: itemMouse.isDragActive

                    property real shiftX: {
                        let dragIdx = dockRow.activeDragIndex
                        if (dragIdx < 0 || dragIdx === index) return 0.0;
                        let spaces = dockRow.activeOffsetSpaces
                        if (spaces > 0 && index > dragIdx && index <= dragIdx + spaces) {
                            return -48.0
                        } else if (spaces < 0 && index < dragIdx && index >= dragIdx + spaces) {
                            return 48.0
                        }
                        return 0.0
                    }

                    // Visual Content Container (Translates smoothly without moving MouseArea)
                    Item {
                        id: visualContainer
                        anchors.fill: parent
                        scale: isDraggingThis ? 1.2 : 1.0
                        z: isDraggingThis ? 99 : 1

                        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

                        transform: Translate {
                            x: isDraggingThis ? itemMouse.dragXOffset : dockItem.shiftX
                            Behavior on x {
                                NumberAnimation {
                                    duration: isDraggingThis ? 0 : 250
                                    easing.type: Easing.OutBack
                                }
                            }
                        }

                        // Subtle Active / Hover Background Capsule (Clean soft glow, no top border line)
                        Rectangle {
                            anchors.fill: parent
                            radius: 8
                            color: isAppActive ? Qt.rgba(139/255, 233/255, 253/255, 0.22) : (isHovered ? Qt.rgba(255/255, 255/255, 255/255, 0.08) : "transparent")
                            border.color: isAppActive ? Theme.accent : "transparent"
                            border.width: isAppActive ? 1 : 0

                            Behavior on color { ColorAnimation { duration: 120 } }
                        }

                        // Scalable Icon Container (Uniform 26x26 size and 1.12 hover scale)
                        Item {
                            anchors.centerIn: parent
                            width: 26
                            height: 26
                            scale: isHovered ? 1.12 : 1.0

                            Behavior on scale {
                                NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
                            }

                            Image {
                                anchors.fill: parent
                                sourceSize.width: 26
                                sourceSize.height: 26
                                fillMode: Image.PreserveAspectFit
                                source: getIconPath(modelData.icon || modelData.appId)
                            }
                        }

                        // Running / Active Indicator Bar at Bottom (Sleek Compact Indicator)
                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 3
                            height: 3
                            width: isAppActive ? 12 : (isAppRunning ? 4 : 0)
                            radius: 1.5
                            color: isAppActive ? Theme.accent : Theme.subAccent
                            visible: isAppRunning || isAppActive

                            Behavior on width {
                                NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                            }
                        }

                    }

                    // Mouse Interaction Area (Fixed Layout Sibling - Supports Pinned Reorder & Unpinned Bounce-Back)
                    MouseArea {
                        id: itemMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton

                        property real dragXOffset: 0
                        property real pressStartX: 0
                        property bool isDragActive: false

                        drag.axis: Drag.XAxis
                        drag.minimumX: -(index * 48)
                        drag.maximumX: (TaskService.allDockApps.length - 1 - index) * 48

                        onPressed: (mouse) => {
                            if (mouse.button === Qt.LeftButton) {
                                pressStartX = mouse.x
                                isDragActive = false
                                dragXOffset = 0
                                dockRow.activeDragIndex = index
                                dockRow.activeDragXOffset = 0
                            }
                        }

                        onPositionChanged: (mouse) => {
                            if (pressed && (mouse.buttons & Qt.LeftButton)) {
                                dragXOffset = mouse.x - pressStartX
                                if (Math.abs(dragXOffset) > 6) {
                                    isDragActive = true
                                }
                                dockRow.activeDragXOffset = dragXOffset
                            }
                        }

                        onReleased: (mouse) => {
                            let wasDragging = isDragActive
                            let finalOffset = dragXOffset

                            // Reset state immediately (for unpinned apps, dragXOffset reset triggers smooth OutBack bounce-back)
                            dragXOffset = 0
                            isDragActive = false
                            dockRow.activeDragIndex = -1
                            dockRow.activeDragXOffset = 0

                            if (wasDragging) {
                                if (modelData.isPinned) {
                                    let offsetSpaces = Math.round(finalOffset / 48.0)
                                    let targetIndex = Math.max(0, Math.min(TaskService.pinnedApps.length - 1, index + offsetSpaces))
                                    if (targetIndex !== index) {
                                        TaskService.reorderPinnedApps(index, targetIndex)
                                    }
                                }
                            } else if (mouse.button === Qt.LeftButton) {
                                let globalPos = dockItem.mapToItem(null, 0, 0)
                                TaskService.focusApp(modelData.appId, modelData.cmd, globalPos.x, globalPos.y)
                            } else if (mouse.button === Qt.RightButton) {
                                root.contextTargetApp = modelData
                                root.contextTargetX = Math.round(dockItem.mapToItem(null, 0, 0).x)
                                PopupService.toggleDockMenu()
                            }
                        }
                    }
                }
            }

            // 3. Right Vertical Separator Line (to the right of Task Manager)
            Rectangle {
                width: 1
                height: 22
                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: 2
                Layout.rightMargin: 2
                color: Theme.separator
            }

            // 4. Theme Switcher Button (Dracula Pro Variants)
            Item {
                id: themeBtn
                width: 42
                height: 42
                Layout.alignment: Qt.AlignVCenter

                property bool isHovered: themeMouse.containsMouse

                // Hover Capsule Background
                Rectangle {
                    anchors.fill: parent
                    radius: 8
                    color: themeBtn.isHovered ? Qt.rgba(255/255, 255/255, 255/255, 0.08) : "transparent"
                    Behavior on color { ColorAnimation { duration: 120 } }
                }

                // Swatch / Palette Canvas Icon with active Dracula Pro Accent
                Item {
                    anchors.centerIn: parent
                    width: 24
                    height: 24
                    scale: themeBtn.isHovered ? 1.14 : 1.0
                    Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

                    Canvas {
                        id: themeIconCanvas
                        anchors.fill: parent
                        onPaint: {
                            var ctx = getContext("2d")
                            ctx.reset()
                            let w = width
                            let h = height

                            // Outer Ring
                            ctx.beginPath()
                            ctx.arc(w/2, h/2, 9, 0, 2 * Math.PI)
                            ctx.fillStyle = Theme.surface
                            ctx.fill()
                            ctx.lineWidth = 1.8
                            ctx.strokeStyle = Theme.accent
                            ctx.stroke()

                            // Inner Glow Dot
                            ctx.beginPath()
                            ctx.arc(w/2, h/2, 4, 0, 2 * Math.PI)
                            ctx.fillStyle = Theme.accent
                            ctx.fill()
                        }

                        Connections {
                            target: Theme
                            function onAccentChanged() { themeIconCanvas.requestPaint() }
                            function onSurfaceChanged() { themeIconCanvas.requestPaint() }
                        }
                    }
                }

                MouseArea {
                    id: themeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: PopupService.toggleThemePicker()
                }
            }
        }
    }

    // Helper: Compute combined list of Pinned Apps + Unpinned Running Windows
    function getCombinedDockModel() {
        let list = Array.from(TaskService.pinnedApps)
        let pinnedIds = list.map(a => a.appId.toLowerCase())

        // Append unpinned running apps
        if (TaskService.runningWindows) {
            for (let i = 0; i < TaskService.runningWindows.length; i++) {
                let win = TaskService.runningWindows[i]
                let app = (win.appId || "").toLowerCase()
                if (app !== "" && !pinnedIds.includes(app)) {
                    pinnedIds.push(app)
                    list.push({
                        appId: win.appId,
                        name: win.title || win.appId,
                        icon: win.appId,
                        cmd: win.appId,
                        toplevel: win.toplevel
                    })
                }
            }
        }
        return list
    }

    // Helper: Icon Path Resolver with Dynamic Path Support
    function getIconPath(iconName) {
        if (!iconName || iconName === "") {
            return AppLauncherService.fallbackIconPath ? "file://" + AppLauncherService.fallbackIconPath : "file:///usr/share/icons/hicolor/scalable/apps/application-x-executable.svg"
        }
        let name = iconName.trim()
        if (name.startsWith("file://")) return name
        if (name.startsWith("/")) return "file://" + name

        let clean = name.toLowerCase().replace(/\.desktop$/, "")
        
        // 1. Dynamic lookup in AppLauncherService iconMap (resolves Flatpak & native app icons dynamically!)
        if (AppLauncherService.iconMap && AppLauncherService.iconMap[clean]) {
            let mapped = AppLauncherService.iconMap[clean]
            return mapped.startsWith("file://") ? mapped : "file://" + mapped
        }

        // 2. Hardcoded fallback overrides for common system apps
        let themeDir = Theme.iconTheme
        if (clean.includes("alacritty")) return "file:///usr/share/icons/" + themeDir + "/32x32/apps/Alacritty.svg"
        if (clean.includes("dolphin")) return "file:///usr/share/icons/" + themeDir + "/32x32/apps/org.kde.dolphin.svg"
        if (clean.includes("firefox")) return "file:///usr/share/icons/" + themeDir + "/32x32/apps/firefox.svg"
        if (clean.includes("code") || clean.includes("visualstudio")) return "file:///usr/share/icons/" + themeDir + "/32x32/apps/com.visualstudio.code.svg"
        if (clean.includes("kate")) return "file:///usr/share/icons/" + themeDir + "/32x32/apps/kate.svg"

        return AppLauncherService.fallbackIconPath ? "file://" + AppLauncherService.fallbackIconPath : "file:///usr/share/icons/hicolor/scalable/apps/application-x-executable.svg"
    }

    // Helper: Formatted Program Name Cleaner
    function getCleanProgramName(app) {
        if (!app) return "Application";
        if (app.name && app.name !== "" && app.name !== app.appId) return app.name;
        let id = app.appId || "";
        if (!id) return "Application";
        let raw = id.includes(".") ? id.split(".").pop() : id;
        raw = raw.replace(/[-_]/g, " ");
        let lower = raw.toLowerCase();
        if (lower === "alacritty") return "Alacritty";
        if (lower === "dolphin") return "Dolphin";
        if (lower === "firefox") return "Firefox";
        if (lower === "code" || lower === "visualstudio") return "VS Code";
        if (lower === "kate") return "Kate";
        if (lower === "spectacle") return "Spectacle";
        if (lower === "zen" || lower.includes("zen")) return "Zen Browser";
        if (lower === "antigravity" || lower.includes("antigravity")) return "Antigravity";
        if (lower === "equibop" || lower.includes("discord")) return "Discord";
        return raw.charAt(0).toUpperCase() + raw.slice(1);
    }

    property var dockWindow: null

    // Dock Context Menu Detached Popup Window
    PopupWindow {
        id: dockContextMenu
        anchor.window: root.dockWindow
        anchor.rect.x: Math.round(root.contextTargetX)
        anchor.rect.y: 0
        anchor.edges: Edges.Top | Edges.Left
        visible: PopupService.dockMenuOpen
        color: "transparent"

        implicitWidth: dockCtxGlass.implicitWidth
        implicitHeight: dockCtxGlass.implicitHeight

        GlassPanel {
            id: dockCtxGlass
            implicitWidth: 160
            implicitHeight: ctxCol.implicitHeight + 16
            anchors.fill: parent

            ColumnLayout {
                id: ctxCol
                anchors.fill: parent
                anchors.margins: 8
                spacing: 4

                // Header Title with Icon (Fixed 22px Height)
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 22
                    spacing: 6

                    Item {
                        width: 14
                        height: 14
                        Layout.alignment: Qt.AlignVCenter

                        Image {
                            anchors.fill: parent
                            sourceSize.width: 14
                            sourceSize.height: 14
                            source: root.contextTargetApp ? root.getIconPath(root.contextTargetApp.icon || root.contextTargetApp.appId) : ""
                            fillMode: Image.PreserveAspectFit
                        }
                    }

                    Text {
                        text: root.contextTargetApp ? root.getCleanProgramName(root.contextTargetApp) : "Application"
                        color: Theme.accent
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                    }
                }

                // Divider
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: Theme.currentLine
                }

                // Option 1: Launch New Instance
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 24
                    radius: 4
                    color: launchMouse.containsMouse ? Theme.currentLine : "transparent"

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Launch New Instance"
                        color: Theme.fg
                        font.pixelSize: 10
                        font.weight: Font.Medium
                    }

                    MouseArea {
                        id: launchMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            if (root.contextTargetApp && root.contextTargetApp.cmd) {
                                TaskService.launchApp(root.contextTargetApp.cmd)
                            }
                            PopupService.closeAll()
                        }
                    }
                }

                // Option 2: Pin / Unpin Toggle
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 24
                    radius: 4
                    color: pinMouse.containsMouse ? Theme.currentLine : "transparent"

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        text: (root.contextTargetApp && TaskService.isPinned(root.contextTargetApp.appId)) ? "Unpin from Dock" : "Pin to Dock"
                        color: Theme.fg
                        font.pixelSize: 10
                        font.weight: Font.Medium
                    }

                    MouseArea {
                        id: pinMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            if (root.contextTargetApp) {
                                TaskService.togglePin(root.contextTargetApp)
                            }
                            PopupService.closeAll()
                        }
                    }
                }

                // Option 3: Close Application (Red text)
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 24
                    radius: 4
                    visible: root.contextTargetApp && TaskService.isRunning(root.contextTargetApp.appId)
                    color: closeMouse.containsMouse ? Qt.rgba(255/255, 85/255, 85/255, 0.2) : "transparent"

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Close Application"
                        color: Theme.red
                        font.pixelSize: 10
                        font.weight: Font.Bold
                    }

                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            if (root.contextTargetApp) {
                                TaskService.closeApp(root.contextTargetApp.appId)
                            }
                            PopupService.closeAll()
                        }
                    }
                }
            }
        }
    }

    Timer {
        id: geomTimer
        interval: 500
        running: true
        repeat: true
        onTriggered: {
            let map = {}
            for (let i = 0; i < dockRepeater.count; i++) {
                let item = dockRepeater.itemAt(i)
                if (item && item.appId) {
                    let pt = item.mapToItem(null, 0, 0)
                    map[item.appId.toLowerCase()] = { x: Math.round(pt.x), y: Math.round(pt.y) }
                }
            }
            TaskService.updateIconGeometries(map)
        }
    }
}
