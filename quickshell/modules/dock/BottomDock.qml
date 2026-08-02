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

                        onEntered: {
                            previewCloseTimer.stop()
                            if (TaskService.isRunning(modelData.appId)) {
                                 let instances = TaskService.getWindowsForApp(modelData.appId)
                                 if (instances && instances.length > 0) {
                                     let targetParent = root.dockWindow ? root.dockWindow.contentItem : root
                                     let pt = itemMouse.mapToItem(targetParent, 0, 0)
                                     root.previewTargetX = Math.round(pt.x + itemMouse.width / 2)
                                     root.isPreviewHovered = true
                                     root.previewActive = true

                                     let oldLen = root.previewWindowInstances ? root.previewWindowInstances.length : 0
                                     let newLen = instances.length
                                     let isDifferentApp = (root.previewTargetApp !== modelData)

                                     root.previewTargetApp = modelData
                                     if (isDifferentApp && oldLen !== newLen && dockWindowPreview.visible) {
                                         root.previewWindowInstances = []
                                         Qt.callLater(() => {
                                             if (root.isPreviewHovered || root.previewActive) {
                                                 root.previewWindowInstances = instances
                                             }
                                         })
                                     } else {
                                         root.previewWindowInstances = instances
                                     }
                                 } else {
                                     root.isPreviewHovered = false
                                     previewCloseTimer.restart()
                                 }
                             } else {
                                 root.isPreviewHovered = false
                                 previewCloseTimer.restart()
                             }
                         }

                        onExited: {
                            root.isPreviewHovered = false
                            previewCloseTimer.restart()
                        }

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
                                let globalPos = itemMouse.mapToItem(root, 0, 0)
                                TaskService.focusApp(modelData.appId, modelData.cmd, globalPos.x, globalPos.y)
                            } else if (mouse.button === Qt.RightButton) {
                                root.isPreviewHovered = false
                                root.isCardHovered = false
                                previewCloseTimer.stop()

                                root.contextTargetApp = modelData
                                let targetParent = root.dockWindow ? root.dockWindow.contentItem : root
                                let posInWindow = itemMouse.mapToItem(targetParent, 0, 0).x
                                root.contextTargetX = Math.round(posInWindow)

                                dockContextMenu.visible = true
                                PopupService.dockMenuOpen = true
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

        // 2. Hardcoded fallback overrides for common system apps & games
        let themeDir = Theme.iconTheme
        if (clean.includes("overwatch") || clean.includes("2357570")) {
            return "file:///usr/share/icons/" + themeDir + "/64x64/apps/overwatch.svg"
        }
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
        if (app.name && app.name !== "" && app.name !== app.appId && app.name !== "Steam Game (2357570)") return app.name;
        let id = app.appId || "";
        if (!id) return "Application";
        let raw = id.includes(".") ? id.split(".").pop() : id;
        raw = raw.replace(/[-_]/g, " ");
        let lower = raw.toLowerCase();
        if (lower.includes("overwatch") || lower.includes("2357570")) return "Overwatch 2";
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

    function getToplevelForWindow(winObj) {
        if (!winObj || typeof ToplevelManager === "undefined" || !ToplevelManager.toplevels) return null;
        let list = ToplevelManager.toplevels.values;
        if (!list || list.length === 0) return null;

        let targetApp = (winObj.appId || "").toLowerCase().trim();
        let targetTitle = (winObj.caption || winObj.name || "").toLowerCase().trim();

        for (let i = 0; i < list.length; i++) {
            let t = list[i];
            if (!t) continue;
            let tApp = (t.appId || "").toLowerCase().trim();
            let tTitle = (t.title || "").toLowerCase().trim();

            if (tApp === targetApp || (tApp && targetApp && (tApp.includes(targetApp) || targetApp.includes(tApp)))) {
                if (!targetTitle || tTitle.includes(targetTitle) || targetTitle.includes(tTitle)) {
                    return t;
                }
            }
        }

        for (let i = 0; i < list.length; i++) {
            let t = list[i];
            if (!t) continue;
            let tApp = (t.appId || "").toLowerCase().trim();
            if (tApp === targetApp || (tApp && targetApp && (tApp.includes(targetApp) || targetApp.includes(tApp)))) {
                return t;
            }
        }

        return null;
    }

    function calculateCardsRowWidth(instances) {
        if (!instances || !Array.isArray(instances) || instances.length === 0) return 180;
        let totalW = 0;
        for (let i = 0; i < instances.length; i++) {
            let w = instances[i];
            let winW = (w && w.width && Number(w.width) > 50) ? Number(w.width) : 1280;
            let winH = (w && w.height && Number(w.height) > 50) ? Number(w.height) : 800;
            let aspect = Math.max(0.6, Math.min(2.2, winW / winH));
            let cardW = Math.max(160, Math.min(260, Math.round(130 * aspect)));
            totalW += cardW;
        }
        totalW += Math.max(0, (instances.length - 1) * 10);
        return totalW;
    }

    property var dockWindow: null

    // Window Preview Hover State Properties
    property var previewTargetApp: null
    property var previewWindowInstances: []
    property int previewTargetX: 0
    property bool isPreviewHovered: false
    property bool isCardHovered: false
    property bool previewActive: false

    Timer {
        id: previewCloseTimer
        interval: 180
        repeat: false
        onTriggered: {
            if (!root.isPreviewHovered && !previewMouseArea.containsMouse && !root.isCardHovered) {
                root.previewActive = false
                root.isPreviewHovered = false
                root.isCardHovered = false
            }
        }
    }

    // Live Window Preview Floating Popup Window (Hysteresis Active Binding)
    PopupWindow {
        id: dockWindowPreview
        anchor.window: root.dockWindow
        anchor.rect.x: Math.max(10, Math.min(root.dockWindow ? root.dockWindow.width - previewGlass.implicitWidth - 10 : 800, root.previewTargetX - Math.round(previewGlass.implicitWidth / 2) + 21))
        anchor.rect.y: 0
        anchor.edges: Edges.Top | Edges.Left
        visible: root.previewActive && (root.previewWindowInstances && root.previewWindowInstances.length > 0)
        color: "transparent"

        implicitWidth: previewGlass.implicitWidth
        implicitHeight: previewGlass.implicitHeight

        MouseArea {
            id: previewMouseArea
            anchors.fill: parent
            hoverEnabled: true
            onEntered: {
                previewCloseTimer.stop()
                root.previewActive = true
            }
            onExited: {
                if (!root.isPreviewHovered) {
                    previewCloseTimer.restart()
                }
            }

            GlassPanel {
                id: previewGlass
                implicitWidth: previewMainCol.implicitWidth + 24
                implicitHeight: previewMainCol.implicitHeight + 16
                anchors.fill: parent

                ColumnLayout {
                    id: previewMainCol
                    anchors.centerIn: parent
                    spacing: 8

                    // Header: App Title & Running Count
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Item {
                            width: 14
                            height: 14
                            Layout.alignment: Qt.AlignVCenter

                            Image {
                                anchors.fill: parent
                                sourceSize.width: 14
                                sourceSize.height: 14
                                fillMode: Image.PreserveAspectFit
                                source: root.getIconPath(root.previewTargetApp ? root.previewTargetApp.icon : "")
                            }
                        }

                        Text {
                            text: root.previewTargetApp ? root.getCleanProgramName(root.previewTargetApp) : "Windows"
                            color: Theme.fg
                            font.pixelSize: 11
                            font.weight: Font.Bold
                            Layout.alignment: Qt.AlignVCenter
                        }

                        Item { Layout.fillWidth: true }

                        Rectangle {
                            height: 16
                            width: countTxt.implicitWidth + 10
                            radius: 8
                            color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.20)
                            border.color: Theme.accent
                            border.width: 1
                            Layout.alignment: Qt.AlignVCenter

                            Text {
                                id: countTxt
                                anchors.centerIn: parent
                                text: root.previewWindowInstances ? root.previewWindowInstances.length + (root.previewWindowInstances.length === 1 ? " Window" : " Windows") : "0"
                                color: Theme.accent
                                font.pixelSize: 9
                                font.weight: Font.Bold
                            }
                        }
                    }

                    // Window Preview Card Row (Single or Multiple Instances)
                    RowLayout {
                        id: previewCardsRow
                        implicitWidth: root.calculateCardsRowWidth(root.previewWindowInstances)
                        spacing: 10

                        Repeater {
                            model: root.previewWindowInstances

                            Item {
                                id: cardItem
                                property real winW: (modelData && modelData.width && Number(modelData.width) > 50) ? Number(modelData.width) : 1280
                                property real winH: (modelData && modelData.height && Number(modelData.height) > 50) ? Number(modelData.height) : 800
                                property real winAspect: Math.max(0.6, Math.min(2.2, winW / winH))
                                implicitWidth: Math.max(160, Math.min(260, Math.round(130 * winAspect)))
                                implicitHeight: 140
                                Layout.preferredWidth: implicitWidth
                                Layout.preferredHeight: implicitHeight

                                property bool cardHovered: cardMouseArea.containsMouse

                                Rectangle {
                                    anchors.fill: parent
                                    radius: 10
                                    color: cardItem.cardHovered ? Qt.rgba(255/255, 255/255, 255/255, 0.10) : Qt.rgba(0, 0, 0, 0.35)
                                    border.color: modelData.active ? Theme.accent : (cardItem.cardHovered ? Theme.subAccent : Theme.separator)
                                    border.width: modelData.active || cardItem.cardHovered ? 1.5 : 1

                                    Behavior on color { ColorAnimation { duration: 120 } }
                                    Behavior on border.color { ColorAnimation { duration: 120 } }
                                    MouseArea {
                                         id: cardMouseArea
                                         anchors.fill: parent
                                         hoverEnabled: true
                                         acceptedButtons: Qt.LeftButton | Qt.RightButton
                                         onEntered: { root.isCardHovered = true; root.previewActive = true; previewCloseTimer.stop() }
                                         onExited: { root.isCardHovered = false; previewCloseTimer.restart() }
                                         onClicked: (mouse) => {
                                             if (mouse.button === Qt.RightButton) {
                                                 root.previewActive = false
                                                 root.isPreviewHovered = false
                                                 root.isCardHovered = false
                                                 previewCloseTimer.stop()
                                                 dockContextMenu.visible = true
                                                 PopupService.dockMenuOpen = true
                                             } else {
                                                 let globalPos = cardItem.mapToItem(root, 0, 0)
                                                 TaskService.focusSpecificWindow(modelData, globalPos.x, globalPos.y)
                                                 root.previewActive = false
                                                 root.isPreviewHovered = false
                                                 root.isCardHovered = false
                                             }
                                         }
                                     }

                                     ColumnLayout {
                                         anchors.fill: parent
                                         anchors.margins: 8
                                         spacing: 6

                                         // Card Header: Window Caption & Close Button
                                         RowLayout {
                                             Layout.fillWidth: true
                                             spacing: 6

                                             Rectangle {
                                                 width: 6
                                                 height: 6
                                                 radius: 3
                                                 color: modelData.active ? Theme.accent : Theme.comment
                                                 Layout.alignment: Qt.AlignVCenter
                                             }

                                             Text {
                                                 id: cardCaptionText
                                                 text: modelData.caption || modelData.name || "Window"
                                                 color: modelData.active ? Theme.accent : Theme.fg
                                                 font.pixelSize: 10
                                                 font.weight: modelData.active ? Font.Bold : Font.Normal
                                                 elide: Text.ElideRight
                                                 Layout.fillWidth: true
                                                 Layout.alignment: Qt.AlignVCenter
                                             }

                                             // Individual Window Close Button (✕)
                                             Item {
                                                 width: 18
                                                 height: 18
                                                 z: 10
                                                 Layout.alignment: Qt.AlignVCenter

                                                 Rectangle {
                                                     anchors.fill: parent
                                                     radius: 9
                                                     color: closeMouse.containsMouse ? Qt.rgba(255/255, 85/255, 85/255, 0.70) : Qt.rgba(0, 0, 0, 0.40)
                                                     Text {
                                                         anchors.centerIn: parent
                                                         text: "✕"
                                                         color: closeMouse.containsMouse ? "#ffffff" : Theme.comment
                                                         font.pixelSize: 10
                                                         font.weight: Font.Bold
                                                     }

                                                     MouseArea {
                                                         id: closeMouse
                                                         anchors.fill: parent
                                                         hoverEnabled: true
                                                         acceptedButtons: Qt.LeftButton
                                                         onEntered: { root.isCardHovered = true; root.previewActive = true; previewCloseTimer.stop() }
                                                         onExited: { root.isCardHovered = false; previewCloseTimer.restart() }
                                                         onPressed: (mouse) => { mouse.accepted = true }
                                                         onClicked: (mouse) => {
                                                             mouse.accepted = true
                                                             TaskService.closeSpecificWindow(modelData)
                                                             let targetId = String(modelData ? (modelData.id || "") : "")
                                                             let rem = root.previewWindowInstances ? root.previewWindowInstances.filter(w => String(w ? (w.id || "") : "") !== targetId) : []
                                                             root.previewWindowInstances = rem
                                                             if (!rem || rem.length === 0) {
                                                                 root.previewActive = false
                                                                 root.isPreviewHovered = false
                                                                 root.isCardHovered = false
                                                                 previewCloseTimer.stop()
                                                             }
                                                         }
                                                     }
                                                 }
                                             }
                                         }

                                        // Lightweight Glass Window Card Viewport (0% CPU, 0ms lag)
                                        Rectangle {
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            radius: 6
                                            color: Qt.rgba(0, 0, 0, 0.45)
                                            border.color: Theme.separator
                                            border.width: 1
                                            clip: true

                                            Image {
                                                anchors.centerIn: parent
                                                width: 38
                                                height: 38
                                                sourceSize.width: 38
                                                sourceSize.height: 38
                                                fillMode: Image.PreserveAspectFit
                                                opacity: 0.85
                                                source: root.getIconPath(modelData.icon || (root.previewTargetApp ? root.previewTargetApp.icon : ""))
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Dock Context Menu Detached Popup Window
    PopupWindow {
        id: dockContextMenu
        anchor.window: root.dockWindow
        anchor.rect.x: Math.max(10, Math.min(root.dockWindow ? root.dockWindow.width - dockCtxGlass.implicitWidth - 10 : 800, root.contextTargetX - Math.round(dockCtxGlass.implicitWidth / 2) + 21))
        anchor.rect.y: 0
        anchor.edges: Edges.Top | Edges.Left
        visible: false
        color: "transparent"

        implicitWidth: dockCtxGlass.implicitWidth
        implicitHeight: dockCtxGlass.implicitHeight

        property real animProgress: 0.0

        NumberAnimation on animProgress {
            id: dockMenuPopIn
            running: false
            to: 1.0
            duration: 220
            easing.type: Easing.OutBack
            easing.overshoot: 1.15
        }

        NumberAnimation on animProgress {
            id: dockMenuPopOut
            running: false
            to: 0.0
            duration: 160
            easing.type: Easing.InQuad
            onFinished: dockContextMenu.visible = false
        }

        Connections {
            target: PopupService
            function onDockMenuOpenChanged() {
                if (PopupService.dockMenuOpen) {
                    dockMenuPopOut.running = false
                    dockContextMenu.visible = true
                    dockMenuPopIn.restart()
                } else if (dockContextMenu.visible) {
                    dockMenuPopIn.running = false
                    dockMenuPopOut.restart()
                }
            }
        }

        GlassPanel {
            id: dockCtxGlass
            implicitWidth: 160
            implicitHeight: ctxCol.implicitHeight + 16
            anchors.fill: parent

            opacity: dockContextMenu.animProgress
            scale: 0.90 + 0.10 * dockContextMenu.animProgress
            transformOrigin: Item.BottomLeft

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
                    let pt = item.mapToItem(root, 0, 0)
                    map[item.appId.toLowerCase()] = { x: Math.round(pt.x), y: Math.round(pt.y) }
                }
            }
            TaskService.updateIconGeometries(map)
        }
    }
}
