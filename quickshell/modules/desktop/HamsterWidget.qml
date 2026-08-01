import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import "../../theme"
import "../../services"

PanelWindow {
    id: hamsterWindow

    anchors {
        bottom: true
        left: true
    }
    margins {
        bottom: 74
        left: 20
    }

    WlrLayershell.layer: WlrLayershell.Bottom
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    mask: Region {}

    implicitWidth: card.implicitWidth
    implicitHeight: card.implicitHeight

    // Standalone Bigger Running Hamster Engine Card (Bottom Left)
    Rectangle {
        id: card
        implicitWidth: 162
        implicitHeight: 184
        radius: 16
        color: Theme.surface
        border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.35)
        border.width: 1.5

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 3
            spacing: 0

            // Hamster GIF Image (Maximizes GIF bounds with minimal border gap)
            Item {
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
                implicitHeight: 145

                AnimatedImage {
                    id: hamsterGif
                    anchors.fill: parent
                    anchors.margins: 0
                    source: "file://" + Quickshell.env("HOME") + "/.config/quickshell/assets/hampter_transparent.gif"
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    playing: !TaskService.isFullscreen
                    speed: Math.max(0.6, Math.min(3.5, 0.8 + (SystemMonitorService.cpuPct * 0.035)))
                }
            }

            Text {
                text: "🐹 Hamster Engine"
                color: Theme.accent
                font.pixelSize: 11
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
}
