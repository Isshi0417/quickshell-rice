import QtQuick
import QtQuick.Layouts
import "../../components"
import "../../services"
import "../../theme"

Item {
    id: root

    visible: PopupService.themePickerOpen

    property string activeTab: "themes" // "themes" or "wallpapers"
    property string activeCategory: "All"
    property var catFlickRef: catFlick

    readonly property var filteredVariants: {
        if (activeCategory === "All") return Theme.variants;
        let list = [];
        for (let i = 0; i < Theme.variants.length; i++) {
            let v = Theme.variants[i];
            if (v.category === activeCategory) list.push(v);
        }
        return list;
    }

    readonly property var filteredWallpapers: {
        if (!WallpaperService.wallpapers) return [];
        let curVar = Theme.currentVariant.toLowerCase().trim();
        let list = [];
        for (let i = 0; i < WallpaperService.wallpapers.length; i++) {
            let wp = WallpaperService.wallpapers[i];
            let wpVar = (wp.variant || "").toLowerCase().trim();
            if (wpVar === curVar || wpVar === "custom") {
                list.push(wp);
            }
        }
        return list;
    }

    implicitWidth: 360
    implicitHeight: 300

    GlassPanel {
        anchors.fill: parent
        radius: 16

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 8

            // ── Header Segmented Tabs ──────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                // Segmented Button: Themes / Wallpapers
                Rectangle {
                    implicitWidth: 180
                    implicitHeight: 28
                    radius: 14
                    color: Qt.rgba(0, 0, 0, 0.25)
                    border.color: Qt.rgba(255/255, 255/255, 255/255, 0.1)

                    Row {
                        anchors.fill: parent
                        anchors.margins: 2
                        spacing: 2

                        // Themes Tab
                        Rectangle {
                            width: 88
                            height: 24
                            radius: 12
                            color: root.activeTab === "themes" ? Theme.accent : "transparent"

                            Behavior on color { ColorAnimation { duration: 110 } }

                            Text {
                                anchors.centerIn: parent
                                text: "Themes"
                                color: root.activeTab === "themes" ? (Theme.isDark ? Theme.bg : "#ffffff") : Theme.comment
                                font.pixelSize: 11
                                font.weight: root.activeTab === "themes" ? Font.Bold : Font.Normal
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: root.activeTab = "themes"
                            }
                        }

                        // Wallpapers Tab
                        Rectangle {
                            width: 88
                            height: 24
                            radius: 12
                            color: root.activeTab === "wallpapers" ? Theme.accent : "transparent"

                            Behavior on color { ColorAnimation { duration: 110 } }

                            Text {
                                anchors.centerIn: parent
                                text: "Wallpapers"
                                color: root.activeTab === "wallpapers" ? (Theme.isDark ? Theme.bg : "#ffffff") : Theme.comment
                                font.pixelSize: 11
                                font.weight: root.activeTab === "wallpapers" ? Font.Bold : Font.Normal
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    root.activeTab = "wallpapers"
                                    WallpaperService.refresh()
                                }
                            }
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                // Active Badge
                Rectangle {
                    implicitWidth: badgeText.implicitWidth + 14
                    implicitHeight: 22
                    radius: 11
                    color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.18)
                    border.color: Theme.accent
                    border.width: 1

                    Text {
                        id: badgeText
                        anchors.centerIn: parent
                        text: root.activeTab === "themes" ? Theme.currentVariant : Theme.currentVariant + " (" + root.filteredWallpapers.length + ")"
                        color: Theme.accent
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                    }
                }
            }

            // ── Categories Horizontal Filter Bar (Themes Tab Only) ─────────────
            Flickable {
                id: catFlick
                visible: root.activeTab === "themes"
                Layout.fillWidth: true
                implicitHeight: visible ? 28 : 0
                clip: true
                contentWidth: catRow.implicitWidth
                boundsBehavior: Flickable.StopAtBounds

                Row {
                    id: catRow
                    spacing: 6

                    Repeater {
                        model: Theme.themeCategories

                        Rectangle {
                            implicitWidth: catTxt.implicitWidth + 16
                            implicitHeight: 26
                            radius: 13

                            property bool isActiveCat: root.activeCategory === modelData

                            color: isActiveCat ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.22)
                                               : (catMouse.containsMouse ? Theme.surface : Qt.rgba(0,0,0,0.15))
                            border.color: isActiveCat ? Theme.accent : "transparent"
                            border.width: 1

                            Behavior on color { ColorAnimation { duration: 110 } }

                            Text {
                                id: catTxt
                                anchors.centerIn: parent
                                text: modelData
                                color: isActiveCat ? Theme.accent : (catMouse.containsMouse ? Theme.fg : Theme.comment)
                                font.pixelSize: 11
                                font.weight: isActiveCat ? Font.Bold : Font.Normal
                            }

                            MouseArea {
                                id: catMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: root.activeCategory = modelData
                                onWheel: (wheel) => {
                                    let delta = wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : wheel.angleDelta.x
                                    if (root.catFlickRef) {
                                        let cf = root.catFlickRef
                                        cf.contentX = Math.max(0, Math.min(cf.contentWidth - cf.width, cf.contentX - delta * 0.8))
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Divider Line
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Qt.rgba(255/255, 255/255, 255/255, 0.1)
            }

            // ── Scrollable Container for Themes & Wallpapers ──────────────────
            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                contentWidth: width
                contentHeight: root.activeTab === "themes" ? themeGrid.implicitHeight : wpGrid.implicitHeight
                boundsBehavior: Flickable.StopAtBounds

                // Color Themes Grid
                Grid {
                    id: themeGrid
                    visible: root.activeTab === "themes"
                    width: parent.width
                    columns: 2
                    spacing: 8

                    Repeater {
                        model: root.filteredVariants

                        Rectangle {
                            width: Math.floor((themeGrid.width - 8) / 2)
                            height: 44
                            radius: 10
                            color: isSelected ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.18)
                                              : (itemMouse.containsMouse ? Theme.surface : Qt.rgba(0, 0, 0, 0.2))

                            border.color: isSelected ? Theme.accent : (itemMouse.containsMouse ? Theme.comment : "transparent")
                            border.width: isSelected ? 2 : 1

                            property bool isSelected: Theme.currentVariant === modelData.name

                            Behavior on color { ColorAnimation { duration: 110 } }
                            Behavior on border.color { ColorAnimation { duration: 110 } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                spacing: 6

                                // Color Swatch Circles (Accent & SubAccent)
                                Item {
                                    width: 24
                                    height: 24
                                    Layout.alignment: Qt.AlignVCenter

                                    Rectangle {
                                        width: 16
                                        height: 16
                                        radius: 8
                                        anchors.left: parent.left
                                        anchors.top: parent.top
                                        color: modelData.accent
                                        border.color: "#1e1e2e"
                                        border.width: 1.5
                                    }

                                    Rectangle {
                                        width: 12
                                        height: 12
                                        radius: 6
                                        anchors.right: parent.right
                                        anchors.bottom: parent.bottom
                                        color: modelData.subAccent
                                        border.color: "#1e1e2e"
                                        border.width: 1.5
                                    }
                                }

                                // Theme Name Text
                                Text {
                                    text: modelData.name
                                    color: isSelected ? Theme.accent : Theme.fg
                                    font.pixelSize: 12
                                    font.weight: isSelected ? Font.Bold : Font.Normal
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }

                                // Active Checkmark Icon
                                Text {
                                    visible: isSelected
                                    text: "✓"
                                    color: Theme.accent
                                    font.pixelSize: 12
                                    font.weight: Font.Bold
                                }
                            }

                            MouseArea {
                                id: itemMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    Theme.setVariant(modelData.name)
                                }
                            }
                        }
                    }
                }

                // ── Sleek Compact Wallpaper Previews for Active Variant ───────────────
                Grid {
                    id: wpGrid
                    visible: root.activeTab === "wallpapers"
                    width: parent.width
                    columns: 2
                    spacing: 8

                    Repeater {
                        model: root.filteredWallpapers

                        Rectangle {
                            width: Math.floor((wpGrid.width - 8) / 2)
                            height: 85
                            radius: 10
                            color: Qt.rgba(0, 0, 0, 0.25)
                            border.color: isSelected ? Theme.accent : (wpMouse.containsMouse ? Theme.comment : Qt.rgba(255/255, 255/255, 255/255, 0.15))
                            border.width: isSelected ? 2 : 1

                            property bool isSelected: Theme.wallpaperPath.endsWith("/" + modelData.name) || WallpaperService.activeCustomWallpaper === modelData.path

                            Behavior on border.color { ColorAnimation { duration: 110 } }

                            // Inner container ensuring clean rounded image rendering without texture noise
                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: 2
                                radius: 8
                                clip: true
                                color: Theme.bg

                                Image {
                                    anchors.fill: parent
                                    fillMode: Image.PreserveAspectCrop
                                    source: "file://" + modelData.path
                                    asynchronous: true
                                    cache: true
                                }
                            }

                            MouseArea {
                                id: wpMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    WallpaperService.applyWallpaper(modelData.path)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
