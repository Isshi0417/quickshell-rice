import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import "../../components"
import "../../services"
import "../../theme"

// Full-screen Application Dashboard
PanelWindow {
    id: root

    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    WlrLayershell.layer: WlrLayershell.Overlay
    WlrLayershell.keyboardFocus: WlrLayershell.Exclusive

    visible: PopupService.appLauncherOpen

    // Currently highlighted app index for keyboard navigation
    property int selectedIndex: 0

    // ── Open / Close animation state ─────────────────────────────────────
    property real openProgress: 0.0

    NumberAnimation on openProgress {
        id: openAnim
        running: false
        to: 1.0
        duration: 220
        easing.type: Easing.OutBack
        easing.overshoot: 1.2
    }

    NumberAnimation on openProgress {
        id: closeAnim
        running: false
        to: 0.0
        duration: 160
        easing.type: Easing.InBack
        easing.overshoot: 1.2
        onFinished: PopupService.appLauncherOpen = false
    }

    onVisibleChanged: {
        if (visible) {
            closeAnim.running = false
            openProgress = 0.0
            openAnim.restart()
            AppLauncherService.reset()
            searchField.text = ""
            root.selectedIndex = 0
            Qt.callLater(() => {
                searchField.forceActiveFocus()
                if (appGrid.count > 0) appGrid.positionViewAtIndex(0, GridView.Contain)
            })
        }
    }

    function closeWithAnimation() {
        openAnim.running = false
        closeAnim.restart()
    }

    // ── Dim background ────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.72 * root.openProgress)

        // Click outside panel → close
        MouseArea {
            anchors.fill: parent
            onClicked: root.closeWithAnimation()
        }
    }

    // ── Centre panel ──────────────────────────────────────────────────────
    Item {
        anchors.centerIn: parent
        width: Math.min(parent.width * 0.88, 1100)
        height: Math.min(parent.height * 0.86, 760)

        focus: root.visible
        Keys.onEscapePressed: root.closeWithAnimation()

        opacity: Math.max(0.0, Math.min(1.0, root.openProgress))
        scale: 0.85 + 0.15 * root.openProgress

        // Panel glass card
        Rectangle {
            anchors.fill: parent
            radius: 18
            color: Theme.bg
            border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.18)
            border.width: 1

            // Stop clicks from falling through to dim background
            MouseArea { anchors.fill: parent; onClicked: {} }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 28
                spacing: 20

                // ── Search bar ────────────────────────────────────────────
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 46
                    radius: 12
                    color: Theme.currentLine
                    border.color: searchField.activeFocus
                              ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.55)
                              : Qt.rgba(Theme.currentLine.r, Theme.currentLine.g, Theme.currentLine.b, 0.6)
                    border.width: searchField.activeFocus ? 2 : 1

                    Behavior on border.color { ColorAnimation { duration: 120 } }
                    Behavior on border.width { NumberAnimation { duration: 120 } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        spacing: 10

                        // Search icon (magnifier)
                        Item {
                            width: 16; height: 16
                            Layout.alignment: Qt.AlignVCenter

                            Canvas {
                                id: searchIcon
                                anchors.fill: parent
                                onPaint: {
                                    let ctx = getContext("2d")
                                    ctx.clearRect(0, 0, width, height)
                                    ctx.strokeStyle = searchField.activeFocus ? Theme.accent : Theme.comment
                                    ctx.lineWidth = 1.8
                                    ctx.beginPath()
                                    ctx.arc(6.5, 6.5, 5, 0, Math.PI * 2)
                                    ctx.stroke()
                                    ctx.beginPath()
                                    ctx.moveTo(10.5, 10.5)
                                    ctx.lineTo(15, 15)
                                    ctx.stroke()
                                }
                                Component.onCompleted: requestPaint()
                                Connections {
                                    target: searchField
                                    function onActiveFocusChanged() { searchIcon.requestPaint() }
                                }
                            }
                        }

                        TextInput {
                            id: searchField
                            focus: true
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            color: Theme.fg
                            font.pixelSize: 15
                            font.family: "Inter"
                            selectionColor: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.35)
                            selectedTextColor: Theme.fg
                            clip: true

                            // Placeholder
                            Text {
                                anchors.fill: parent
                                anchors.leftMargin: 0
                                verticalAlignment: Text.AlignVCenter
                                text: "Search applications…"
                                color: Theme.comment
                                font.pixelSize: 15
                                font.family: "Inter"
                                visible: !searchField.text && !searchField.activeFocus
                            }

                            onTextChanged: {
                                AppLauncherService.searchQuery = text
                                root.selectedIndex = 0
                                if (appGrid.count > 0) appGrid.positionViewAtIndex(0, GridView.Contain)
                            }

                            Keys.onPressed: (event) => {
                                let count = AppLauncherService.filteredApps.length
                                if (count === 0) return

                                let cols = Math.max(1, Math.floor(appGrid.width / appGrid.cellWidth))

                                if (event.key === Qt.Key_Right) {
                                    root.selectedIndex = Math.min(count - 1, root.selectedIndex + 1)
                                    appGrid.positionViewAtIndex(root.selectedIndex, GridView.Contain)
                                    event.accepted = true
                                } else if (event.key === Qt.Key_Left) {
                                    root.selectedIndex = Math.max(0, root.selectedIndex - 1)
                                    appGrid.positionViewAtIndex(root.selectedIndex, GridView.Contain)
                                    event.accepted = true
                                } else if (event.key === Qt.Key_Down) {
                                    root.selectedIndex = Math.min(count - 1, root.selectedIndex + cols)
                                    appGrid.positionViewAtIndex(root.selectedIndex, GridView.Contain)
                                    event.accepted = true
                                } else if (event.key === Qt.Key_Up) {
                                    root.selectedIndex = Math.max(0, root.selectedIndex - cols)
                                    appGrid.positionViewAtIndex(root.selectedIndex, GridView.Contain)
                                    event.accepted = true
                                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                    if (root.selectedIndex >= 0 && root.selectedIndex < count) {
                                        AppLauncherService.launch(AppLauncherService.filteredApps[root.selectedIndex])
                                        root.closeWithAnimation()
                                    }
                                    event.accepted = true
                                } else if (event.key === Qt.Key_Escape) {
                                    root.closeWithAnimation()
                                    event.accepted = true
                                }
                            }
                        }

                        // Clear button
                        Rectangle {
                            width: 18; height: 18
                            radius: 9
                            color: clearMouse.containsMouse ? Theme.currentLine : "transparent"
                            visible: searchField.text.length > 0
                            Layout.alignment: Qt.AlignVCenter

                            Behavior on color { ColorAnimation { duration: 100 } }

                            Text {
                                anchors.centerIn: parent
                                text: "✕"
                                color: Theme.comment
                                font.pixelSize: 10
                            }

                            MouseArea {
                                id: clearMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    searchField.text = ""
                                    searchField.forceActiveFocus()
                                }
                            }
                        }
                    }
                }

                // ── Category pills ────────────────────────────────────────
                ListView {
                    id: categoryList
                    Layout.fillWidth: true
                    Layout.preferredHeight: 34
                    orientation: ListView.Horizontal
                    model: AppLauncherService.categories
                    spacing: 6
                    clip: true

                    ScrollBar.horizontal: ScrollBar { policy: ScrollBar.AlwaysOff }

                    delegate: Rectangle {
                        property bool isActive: modelData === AppLauncherService.activeCategory
                        width: catLabel.implicitWidth + 22
                        height: 30
                        radius: 8
                        color: isActive
                               ? Theme.accent
                               : (catMouse.containsMouse ? Theme.currentLine : "transparent")
                        border.color: isActive
                                      ? Theme.accent
                                      : "transparent"
                        border.width: 1

                        Behavior on color { ColorAnimation { duration: 110 } }
                        Behavior on border.color { ColorAnimation { duration: 110 } }

                        Text {
                            id: catLabel
                            anchors.centerIn: parent
                            text: modelData
                            color: isActive ? (Theme.isDark ? Theme.bg : "#ffffff") : (catMouse.containsMouse ? Theme.accent : Theme.fg)
                            font.pixelSize: 12
                            font.weight: isActive ? Font.Bold : Font.Medium

                            Behavior on color { ColorAnimation { duration: 110 } }
                        }

                        MouseArea {
                            id: catMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                AppLauncherService.activeCategory = modelData
                                root.selectedIndex = 0
                            }
                        }
                    }
                }

                // ── App grid ──────────────────────────────────────────────
                GridView {
                    id: appGrid
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    model: AppLauncherService.filteredApps
                    cellWidth: Math.floor(width / Math.max(1, Math.floor(width / 120)))
                    cellHeight: 110

                    ScrollBar.vertical: ScrollBar {
                        id: gridScroll
                        policy: ScrollBar.AsNeeded
                        contentItem: Rectangle {
                            implicitWidth: 4
                            radius: 2
                            color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.4)
                        }
                        background: Rectangle { color: "transparent" }
                    }

                    // Empty state
                    Text {
                        anchors.centerIn: parent
                        visible: appGrid.count === 0
                        text: "No apps found"
                        color: Theme.fg
                        font.pixelSize: 14
                        font.family: "Inter"
                    }

                    delegate: Item {
                        width: appGrid.cellWidth
                        height: appGrid.cellHeight

                        property var app: modelData
                        property bool isSelected: index === root.selectedIndex

                        Rectangle {
                            id: appTile
                            anchors.fill: parent
                            anchors.margins: 4
                            radius: 12
                            color: isSelected
                                   ? Theme.accent
                                   : (tileMouse.containsMouse ? Theme.currentLine : "transparent")
                            border.color: isSelected ? Theme.accent : "transparent"
                            border.width: isSelected ? 2 : 0

                            Behavior on color { ColorAnimation { duration: 100 } }
                            Behavior on border.color { ColorAnimation { duration: 100 } }

                            scale: tileMouse.pressed ? 0.93 : (isSelected || tileMouse.containsMouse ? 1.05 : 1.0)
                            Behavior on scale {
                                NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                            }

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 8
                                width: parent.width - 12

                                // App icon
                                Item {
                                    Layout.alignment: Qt.AlignHCenter
                                    width: 56
                                    height: 56

                                    Image {
                                        id: appIcon
                                        anchors.fill: parent
                                        sourceSize.width: 56
                                        sourceSize.height: 56
                                        fillMode: Image.PreserveAspectFit
                                        source: resolveIcon(app.icon)
                                        smooth: true
                                        asynchronous: true

                                        visible: status === Image.Ready

                                        onStatusChanged: {
                                            if (status === Image.Error && source !== resolveIcon("")) {
                                                source = resolveIcon("")
                                            }
                                        }
                                    }

                                    // Fallback badge container if icon fails or is unavailable
                                    Rectangle {
                                        anchors.fill: parent
                                        radius: 10
                                        color: Theme.currentLine
                                        visible: appIcon.status !== Image.Ready
                                    }
                                }

                                // App name
                                Text {
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignHCenter
                                    text: app.name
                                    color: isSelected ? (Theme.isDark ? Theme.bg : "#ffffff") : Theme.fg
                                    font.pixelSize: 11
                                    font.family: "Inter"
                                    font.weight: isSelected ? Font.DemiBold : Font.Medium
                                    horizontalAlignment: Text.AlignHCenter
                                    elide: Text.ElideRight
                                    maximumLineCount: 2
                                    wrapMode: Text.WordWrap

                                    Behavior on color { ColorAnimation { duration: 100 } }
                                }
                            }

                            MouseArea {
                                id: tileMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                onEntered: root.selectedIndex = index
                                onClicked: {
                                    root.selectedIndex = index
                                    AppLauncherService.launch(app)
                                    root.closeWithAnimation()
                                }
                            }
                        }
                    }
                }

                // ── Footer: app count ─────────────────────────────────────
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: appGrid.count + " app" + (appGrid.count !== 1 ? "s" : "")
                    color: Theme.comment
                    font.pixelSize: 11
                    font.family: "Inter"
                }
            }
        }
    }

    // ── Icon resolution helper ────────────────────────────────────────────
    function resolveIcon(iconName) {
        if (!iconName || iconName === "") {
            return AppLauncherService.fallbackIconPath ? "file://" + AppLauncherService.fallbackIconPath : ""
        }
        if (iconName.startsWith("/")) return "file://" + iconName

        let lower = iconName.toLowerCase().trim()
        if (AppLauncherService.iconMap && AppLauncherService.iconMap[lower]) {
            let mapped = AppLauncherService.iconMap[lower]
            return mapped.startsWith("/") ? "file://" + mapped : mapped
        }

        return AppLauncherService.fallbackIconPath ? "file://" + AppLauncherService.fallbackIconPath : ""
    }
}
