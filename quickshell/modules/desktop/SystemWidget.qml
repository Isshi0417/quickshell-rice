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

        // TOP ROW: 2 Wide Plasmoid Blocks (CPU & GPU)
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            // Top Card 1: CPU Plasmoid Block
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

            // Top Card 2: GPU Plasmoid Block
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

        // BOTTOM ROW: 2 Wide Plasmoid Blocks (RAM & Sensors/Network)
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
                            text: "🧠 RAM"
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
                        Text { text: "Swap: " + SystemMonitorService.swapUsed + " / " + SystemMonitorService.swapTotal + " GB"; color: Theme.yellow; font.pixelSize: 10 }
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
                    spacing: 6

                    Text {
                        text: "🌡️ Sensors & Network"
                        color: Theme.fg
                        font.pixelSize: 12
                        font.weight: Font.Bold
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        RowLayout {
                            spacing: 4
                            Text { text: "💾 NVMe:"; color: Theme.comment; font.pixelSize: 10; font.weight: Font.Bold }
                            Text { text: SystemMonitorService.nvmeTemp + "°C"; color: Theme.cyan; font.pixelSize: 10; font.weight: Font.Bold }
                        }

                        Item { Layout.fillWidth: true }

                        RowLayout {
                            spacing: 4
                            Text { text: "📶 Wi-Fi:"; color: Theme.comment; font.pixelSize: 10; font.weight: Font.Bold }
                            Text { text: SystemMonitorService.wifiSignal; color: Theme.subAccent; font.pixelSize: 10; font.weight: Font.Bold }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        RowLayout {
                            spacing: 4
                            Text { text: "⬇ Net:"; color: Theme.comment; font.pixelSize: 10; font.weight: Font.Bold }
                            Text { text: SystemMonitorService.netRx; color: Theme.green; font.pixelSize: 10; font.weight: Font.Bold }
                        }

                        Item { Layout.fillWidth: true }

                        RowLayout {
                            spacing: 4
                            Text { text: "⬆ Up:"; color: Theme.comment; font.pixelSize: 10; font.weight: Font.Bold }
                            Text { text: SystemMonitorService.netTx; color: Theme.purple; font.pixelSize: 10; font.weight: Font.Bold }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        Text { text: "🔥 Top:"; color: Theme.comment; font.pixelSize: 10; font.weight: Font.Bold }
                        Text {
                            text: SystemMonitorService.topProc + " (" + SystemMonitorService.procCount + " procs)"
                            color: Theme.pink
                            font.pixelSize: 10
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    Item { Layout.fillHeight: true }

                    // Storage Gauge Bar
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 3

                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "Storage"; color: Theme.comment; font.pixelSize: 9 }
                            Item { Layout.fillWidth: true }
                            Text { text: SystemMonitorService.diskUsed + " / " + SystemMonitorService.diskTotal + " GB (" + SystemMonitorService.diskPct + "%)"; color: Theme.yellow; font.pixelSize: 9 }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 6
                            radius: 3
                            color: Theme.bg

                            Rectangle {
                                height: parent.height
                                width: parent.width * (SystemMonitorService.diskPct / 100.0)
                                radius: 3
                                color: Theme.accent
                                Behavior on width { NumberAnimation { duration: 300 } }
                            }
                        }
                    }
                }
            }
        }
    }
}
