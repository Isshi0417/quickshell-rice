import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../components"
import "../../services"
import "../../theme"

GlassPanel {
    id: root
    implicitWidth: mainLayout.implicitWidth + 24
    implicitHeight: 36

    RowLayout {
        id: mainLayout
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: 8

        // Power / Session Trigger Button
        Rectangle {
            id: sessionBtn
            Layout.preferredWidth: 26
            Layout.preferredHeight: 26
            radius: 6
            color: sessionMouse.containsMouse ? Theme.currentLine : "transparent"

            Behavior on color { ColorAnimation { duration: 120 } }

            PowerIcon {
                anchors.centerIn: parent
                color: sessionMouse.containsMouse ? Theme.accent : Theme.fg
                implicitWidth: 13
                implicitHeight: 13
                strokeWidth: 1.6

                Behavior on color { ColorAnimation { duration: 120 } }
            }

            MouseArea {
                id: sessionMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: PopupService.toggleSession()
            }
        }

        // Minimal Divider Line (Shown only when virtual desktops exist)
        Rectangle {
            Layout.preferredWidth: 1
            Layout.preferredHeight: 14
            color: Theme.separator
            visible: WorkspaceService.hasWorkspaces
        }

        // Dynamic Workspace Switcher
        Item {
            id: workspaceContainer
            visible: WorkspaceService.hasWorkspaces
            Layout.preferredWidth: wsRow.implicitWidth
            Layout.preferredHeight: 26

            RowLayout {
                id: wsRow
                anchors.centerIn: parent
                spacing: 2

                Repeater {
                    model: WorkspaceService.workspaceNames

                    Rectangle {
                        id: wsItem
                        property int wsNumber: index + 1
                        property bool isActive: WorkspaceService.activeWorkspace === wsNumber

                        Layout.preferredWidth: wsText.implicitWidth + 14
                        Layout.preferredHeight: 22
                        radius: 5
                        color: isActive ? Theme.accent : (wsItemMouse.containsMouse ? Theme.currentLine : "transparent")

                        Behavior on color { ColorAnimation { duration: 120 } }

                        Text {
                            id: wsText
                            anchors.centerIn: parent
                            text: modelData
                            color: wsItem.isActive ? (Theme.isDark ? Theme.bg : "#ffffff") : (wsItemMouse.containsMouse ? Theme.accent : Theme.fg)
                            font.pixelSize: 11
                            font.weight: wsItem.isActive ? Font.Bold : Font.Medium

                            Behavior on color { ColorAnimation { duration: 120 } }
                        }

                        MouseArea {
                            id: wsItemMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: WorkspaceService.switchTo(wsItem.wsNumber)
                        }
                    }
                }
            }

            // Global Mouse Wheel Scroll Area
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.NoButton

                onWheel: (wheel) => {
                    if (wheel.angleDelta.y < 0) {
                        if (WorkspaceService.activeWorkspace < WorkspaceService.totalWorkspaces) {
                            WorkspaceService.switchTo(WorkspaceService.activeWorkspace + 1)
                        }
                    } else if (wheel.angleDelta.y > 0) {
                        if (WorkspaceService.activeWorkspace > 1) {
                            WorkspaceService.switchTo(WorkspaceService.activeWorkspace - 1)
                        }
                    }
                }
            }
        }
    }

    // Detached Solid Session Popup Window (Controlled by PopupService)
    PopupWindow {
        id: sessionMenu
        anchor.window: window
        anchor.rect.x: 8
        anchor.rect.y: 42
        anchor.edges: Edges.Bottom | Edges.Left
        visible: PopupService.sessionMenuOpen
        color: "transparent"

        implicitWidth: contentGlass.implicitWidth
        implicitHeight: contentGlass.implicitHeight

        GlassPanel {
            id: contentGlass
            implicitWidth: menuLayout.implicitWidth + 16
            implicitHeight: menuLayout.implicitHeight + 12
            anchors.fill: parent

            ColumnLayout {
                id: menuLayout
                anchors.fill: parent
                anchors.margins: 4
                spacing: 2

                // Lock Option
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredWidth: lockRow.implicitWidth + 24
                    Layout.preferredHeight: 28
                    color: lockMouse.containsMouse ? Theme.currentLine : "transparent"
                    radius: 5

                    Behavior on color { ColorAnimation { duration: 100 } }

                    RowLayout {
                        id: lockRow
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 12
                        spacing: 8

                        Rectangle {
                            width: 6; height: 6; radius: 3
                            color: Theme.purple
                            Layout.alignment: Qt.AlignVCenter
                        }
                        Text {
                            text: "Lock"
                            color: Theme.fg
                            font.pixelSize: 11
                            font.weight: Font.Medium
                            Layout.alignment: Qt.AlignVCenter
                        }
                    }

                    MouseArea {
                        id: lockMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: { SessionService.lock(); PopupService.closeAll() }
                    }
                }

                // Reboot Option
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredWidth: rebootRow.implicitWidth + 24
                    Layout.preferredHeight: 28
                    color: rebootMouse.containsMouse ? Theme.currentLine : "transparent"
                    radius: 5

                    Behavior on color { ColorAnimation { duration: 100 } }

                    RowLayout {
                        id: rebootRow
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 12
                        spacing: 8

                        Rectangle {
                            width: 6; height: 6; radius: 3
                            color: Theme.accent
                            Layout.alignment: Qt.AlignVCenter
                        }
                        Text {
                            text: "Reboot"
                            color: Theme.fg
                            font.pixelSize: 11
                            font.weight: Font.Medium
                            Layout.alignment: Qt.AlignVCenter
                        }
                    }

                    MouseArea {
                        id: rebootMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: { SessionService.reboot(); PopupService.closeAll() }
                    }
                }

                // Shutdown Option
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredWidth: shutdownRow.implicitWidth + 24
                    Layout.preferredHeight: 28
                    color: shutdownMouse.containsMouse ? Theme.currentLine : "transparent"
                    radius: 5

                    Behavior on color { ColorAnimation { duration: 100 } }

                    RowLayout {
                        id: shutdownRow
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 12
                        spacing: 8

                        Rectangle {
                            width: 6; height: 6; radius: 3
                            color: Theme.red
                            Layout.alignment: Qt.AlignVCenter
                        }
                        Text {
                            text: "Power Off"
                            color: Theme.red
                            font.pixelSize: 11
                            font.weight: Font.Medium
                            Layout.alignment: Qt.AlignVCenter
                        }
                    }

                    MouseArea {
                        id: shutdownMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: { SessionService.shutdown(); PopupService.closeAll() }
                    }
                }
            }
        }
    }
}
