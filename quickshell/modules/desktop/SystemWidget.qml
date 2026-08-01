import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import "../../theme"
import "../../services"
import "../../components"

PanelWindow {
    id: widgetWindow

    anchors {
        top: true
        left: true
    }
    margins {
        top: 55
        left: 20
    }

    WlrLayershell.layer: WlrLayershell.Bottom
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    mask: Region {}

    implicitWidth: mainCol.implicitWidth
    implicitHeight: mainCol.implicitHeight

    ColumnLayout {
        id: mainCol
        spacing: 12
        implicitWidth: 640

        // TOP ROW: 3 Plasmoid Blocks
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            // Top Card 1: Transparent Running Hamster Engine
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredWidth: 200
                implicitHeight: 165
                radius: 16
                color: Theme.surface
                border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.3)
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10

                    Item {
                        Layout.alignment: Qt.AlignHCenter
                        width: 84
                        height: 84

                        AnimatedImage {
                            id: hamsterGif
                            anchors.fill: parent
                            source: "file://" + Quickshell.env("HOME") + "/.config/quickshell/assets/hampter_transparent.gif"
                            fillMode: Image.PreserveAspectFit
                            smooth: false
                            playing: !TaskService.isFullscreen
                            speed: Math.max(0.6, Math.min(3.5, 0.8 + (SystemMonitorService.cpuPct * 0.035)))
                        }
                    }

                    Text {
                        text: "Hamster Engine"
                        color: Theme.accent
                        font.pixelSize: 12
                        font.weight: Font.Bold
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Text {
                        text: (60 + SystemMonitorService.cpuPct * 3) + " RPM • " + (SystemMonitorService.cpuPct > 70 ? "🔥 Sprinting" : (SystemMonitorService.cpuPct > 20 ? "⚡ Running" : "💤 Trotting"))
                        color: Theme.comment
                        font.pixelSize: 10
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }

            // Top Card 2: CPU Plasmoid Block
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredWidth: 210
                implicitHeight: 165
                radius: 16
                color: Theme.surface
                border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.3)
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 4

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "💻 CPU"
                            color: Theme.fg
                            font.pixelSize: 12
                            font.weight: Font.Bold
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: SystemMonitorService.cpuPct + "%"
                            color: Theme.accent
                            font.pixelSize: 14
                            font.weight: Font.Bold
                        }
                    }

                    // CPU Usage Gauge Bar
                    Rectangle {
                        Layout.fillWidth: true
                        height: 6
                        radius: 3
                        color: Theme.bg

                        Rectangle {
                            height: parent.height
                            width: parent.width * (SystemMonitorService.cpuPct / 100.0)
                            radius: 3
                            color: SystemMonitorService.cpuPct > 80 ? Theme.red : (SystemMonitorService.cpuPct > 50 ? Theme.orange : Theme.accent)
                            Behavior on width { NumberAnimation { duration: 300 } }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "Temp: " + SystemMonitorService.cpuTemp + "°C"; color: SystemMonitorService.cpuTemp > 80 ? Theme.red : Theme.comment; font.pixelSize: 10 }
                        Item { Layout.fillWidth: true }
                        Text { text: "Fan: " + (SystemMonitorService.cpuFan > 0 ? SystemMonitorService.cpuFan + " RPM" : "Quiet"); color: Theme.subAccent; font.pixelSize: 10 }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "Clock: " + SystemMonitorService.cpuFreq; color: Theme.cyan; font.pixelSize: 10 }
                        Item { Layout.fillWidth: true }
                        Text { text: SystemMonitorService.cpuCores + " Cores"; color: Theme.comment; font.pixelSize: 10 }
                    }

                    Item { Layout.fillHeight: true }

                    // Smooth Sparkline Graph for CPU History
                    SparklineGraph {
                        Layout.fillWidth: true
                        historyData: SystemMonitorService.cpuHistory
                        barColor: Theme.accent
                    }
                }
            }

            // Top Card 3: GPU Plasmoid Block
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredWidth: 210
                implicitHeight: 165
                radius: 16
                color: Theme.surface
                border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.3)
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 4

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "🎮 RTX 4060"
                            color: Theme.fg
                            font.pixelSize: 12
                            font.weight: Font.Bold
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: SystemMonitorService.gpuPct + "%"
                            color: Theme.pink
                            font.pixelSize: 14
                            font.weight: Font.Bold
                        }
                    }

                    // GPU Usage Gauge Bar
                    Rectangle {
                        Layout.fillWidth: true
                        height: 6
                        radius: 3
                        color: Theme.bg

                        Rectangle {
                            height: parent.height
                            width: parent.width * (SystemMonitorService.gpuPct / 100.0)
                            radius: 3
                            color: Theme.pink
                            Behavior on width { NumberAnimation { duration: 300 } }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "Temp: " + SystemMonitorService.gpuTemp + "°C"; color: SystemMonitorService.gpuTemp > 75 ? Theme.orange : Theme.comment; font.pixelSize: 10 }
                        Item { Layout.fillWidth: true }
                        Text { text: "Pwr: " + SystemMonitorService.gpuPower; color: Theme.purple; font.pixelSize: 10 }
                    }

                    Text {
                        text: "VRAM: " + SystemMonitorService.gpuVramUsed + " / " + SystemMonitorService.gpuVramTotal + " MB"
                        color: Theme.subAccent
                        font.pixelSize: 10
                    }

                    Item { Layout.fillHeight: true }

                    // Smooth Sparkline Graph for GPU History
                    SparklineGraph {
                        Layout.fillWidth: true
                        historyData: SystemMonitorService.gpuHistory
                        barColor: Theme.pink
                    }
                }
            }
        }

        // BOTTOM ROW: 2 Larger Plasmoid Blocks
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            // Bottom Card 1: RAM & Memory Plasmoid Block
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredWidth: 314
                implicitHeight: 165
                radius: 16
                color: Theme.surface
                border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.3)
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 4

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "🧠 RAM & Memory"
                            color: Theme.fg
                            font.pixelSize: 12
                            font.weight: Font.Bold
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: SystemMonitorService.ramPct + "%"
                            color: Theme.subAccent
                            font.pixelSize: 14
                            font.weight: Font.Bold
                        }
                    }

                    // RAM Usage Gauge Bar
                    Rectangle {
                        Layout.fillWidth: true
                        height: 6
                        radius: 3
                        color: Theme.bg

                        Rectangle {
                            height: parent.height
                            width: parent.width * (SystemMonitorService.ramPct / 100.0)
                            radius: 3
                            color: Theme.subAccent
                            Behavior on width { NumberAnimation { duration: 300 } }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "Used: " + SystemMonitorService.ramUsed + " / " + SystemMonitorService.ramTotal + " GB"; color: Theme.comment; font.pixelSize: 10 }
                        Item { Layout.fillWidth: true }
                        Text { text: "Free: " + (Math.max(0, SystemMonitorService.ramTotal - SystemMonitorService.ramUsed)).toFixed(1) + " GB"; color: Theme.green; font.pixelSize: 10 }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "Swap: " + SystemMonitorService.swapUsed + " / " + SystemMonitorService.swapTotal + " GB"; color: Theme.yellow; font.pixelSize: 10 }
                        Item { Layout.fillWidth: true }
                        Text { text: "Uptime: " + SystemMonitorService.uptime; color: Theme.cyan; font.pixelSize: 10 }
                    }

                    Item { Layout.fillHeight: true }

                    // Smooth Sparkline Graph for RAM History
                    SparklineGraph {
                        Layout.fillWidth: true
                        historyData: SystemMonitorService.ramHistory
                        barColor: Theme.subAccent
                    }
                }
            }

            // Bottom Card 2: Sensors, Network & Processes Plasmoid Block
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredWidth: 314
                implicitHeight: 165
                radius: 16
                color: Theme.surface
                border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.3)
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 4

                    Text {
                        text: "🌡️ Sensors, Network & Storage"
                        color: Theme.fg
                        font.pixelSize: 12
                        font.weight: Font.Bold
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "💾 NVMe: " + SystemMonitorService.nvmeTemp + "°C"; color: Theme.cyan; font.pixelSize: 10; font.weight: Font.Bold }
                        Item { Layout.fillWidth: true }
                        Text { text: "📶 Wi-Fi: " + SystemMonitorService.wifiTemp + "°C"; color: Theme.yellow; font.pixelSize: 10; font.weight: Font.Bold }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "⬇ RX: " + SystemMonitorService.netRx; color: Theme.green; font.pixelSize: 10; font.weight: Font.Bold }
                        Item { Layout.fillWidth: true }
                        Text { text: "⬆ TX: " + SystemMonitorService.netTx; color: Theme.subAccent; font.pixelSize: 10; font.weight: Font.Bold }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "🔥 Top Task: " + SystemMonitorService.topProc; color: Theme.pink; font.pixelSize: 10 }
                        Item { Layout.fillWidth: true }
                        Text { text: SystemMonitorService.procCount + " Processes"; color: Theme.comment; font.pixelSize: 10 }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "💾 Disk: " + SystemMonitorService.diskUsed + " / " + SystemMonitorService.diskTotal + " GB (" + SystemMonitorService.diskPct + "%)"; color: Theme.comment; font.pixelSize: 10 }
                    }

                    // Disk Usage Gauge Bar
                    Rectangle {
                        Layout.fillWidth: true
                        height: 6
                        radius: 3
                        color: Theme.bg

                        Rectangle {
                            height: parent.height
                            width: parent.width * (SystemMonitorService.diskPct / 100.0)
                            radius: 3
                            color: Theme.yellow
                            Behavior on width { NumberAnimation { duration: 300 } }
                        }
                    }
                }
            }
        }
    }
}
