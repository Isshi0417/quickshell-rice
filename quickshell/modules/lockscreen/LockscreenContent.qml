import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../../theme"
import "../../services"

Item {
    id: root

    focus: true

    // Force focus when lockscreen becomes visible
    onVisibleChanged: {
        if (visible) {
            root.forceActiveFocus()
            secretInput.forceActiveFocus()
        }
    }

    Component.onCompleted: {
        root.forceActiveFocus()
        secretInput.forceActiveFocus()
    }

    // Secret hidden TextInput to capture keyboard presses reliably
    TextInput {
        id: secretInput
        anchors.fill: parent
        opacity: 0
        focus: true
        activeFocusOnTab: true
        echoMode: TextInput.Password

        onTextChanged: {
            // Synchronize with LockscreenService
            if (text !== LockscreenService.userPassword) {
                LockscreenService.userPassword = text
                LockscreenService.typedCount = text.length
            }
        }

        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                event.accepted = true
                LockscreenService.submitPassword()
            } else if (event.key === Qt.Key_Escape) {
                event.accepted = true
                secretInput.text = ""
                LockscreenService.clearPassword()
            }
        }
    }

    Connections {
        target: LockscreenService
        function onIsLockedChanged() {
            if (LockscreenService.isLocked) {
                secretInput.text = ""
                root.forceActiveFocus()
                secretInput.forceActiveFocus()
            }
        }
        function onAuthFailedChanged() {
            if (LockscreenService.authFailed) {
                shakeAnim.restart()
                secretInput.text = ""
            }
        }
    }

    // Shake animation on incorrect password
    SequentialAnimation {
        id: shakeAnim
        running: false
        NumberAnimation { target: cardContainer; property: "anchors.horizontalCenterOffset"; to: -24; duration: 40; easing.type: Easing.OutQuad }
        NumberAnimation { target: cardContainer; property: "anchors.horizontalCenterOffset"; to: 24; duration: 50; easing.type: Easing.OutQuad }
        NumberAnimation { target: cardContainer; property: "anchors.horizontalCenterOffset"; to: -16; duration: 50; easing.type: Easing.OutQuad }
        NumberAnimation { target: cardContainer; property: "anchors.horizontalCenterOffset"; to: 16; duration: 50; easing.type: Easing.OutQuad }
        NumberAnimation { target: cardContainer; property: "anchors.horizontalCenterOffset"; to: -8; duration: 40; easing.type: Easing.OutQuad }
        NumberAnimation { target: cardContainer; property: "anchors.horizontalCenterOffset"; to: 8; duration: 40; easing.type: Easing.OutQuad }
        NumberAnimation { target: cardContainer; property: "anchors.horizontalCenterOffset"; to: 0; duration: 40; easing.type: Easing.OutQuad }
    }

    // Click anywhere to focus input
    MouseArea {
        anchors.fill: parent
        onClicked: {
            root.forceActiveFocus()
            secretInput.forceActiveFocus()
        }
    }

    // Main Centered Content Container
    ColumnLayout {
        id: mainColumn
        anchors.centerIn: parent
        spacing: 28
        width: Math.min(520, parent.width - 40)

        // 1. Clock & Date Header
        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 6

            Text {
                id: clockText
                text: {
                    let date = new Date()
                    let h = date.getHours().toString().padStart(2, '0')
                    let m = date.getMinutes().toString().padStart(2, '0')
                    let s = date.getSeconds().toString().padStart(2, '0')
                    return `${h}:${m}:${s}`
                }
                color: Theme.fg
                font.pixelSize: 64
                font.weight: Font.Bold
                font.family: "Sans-Serif"
                Layout.alignment: Qt.AlignHCenter

                Timer {
                    interval: 1000
                    running: true
                    repeat: true
                    onTriggered: clockText.text = {
                        let date = new Date()
                        let h = date.getHours().toString().padStart(2, '0')
                        let m = date.getMinutes().toString().padStart(2, '0')
                        let s = date.getSeconds().toString().padStart(2, '0')
                        return `${h}:${m}:${s}`
                    }
                }
            }

            Text {
                id: dateText
                text: {
                    let date = new Date()
                    let options = { weekday: 'long', month: 'long', day: 'numeric', year: 'numeric' }
                    return date.toLocaleDateString(Qt.locale(), options)
                }
                color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.75)
                font.pixelSize: 15
                font.weight: Font.Medium
                Layout.alignment: Qt.AlignHCenter
            }
        }

        Item { Layout.preferredHeight: 10 }

        // 2. User Avatar & Badge
        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 12

            Rectangle {
                width: 96
                height: 96
                radius: 48
                color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.15)
                border.color: Theme.accent
                border.width: 2
                Layout.alignment: Qt.AlignHCenter

                // Avatar Icon / Initial Badge
                Text {
                    anchors.centerIn: parent
                    text: LockscreenService.username ? LockscreenService.username.charAt(0).toUpperCase() : "🔒"
                    color: Theme.accent
                    font.pixelSize: 42
                    font.weight: Font.Bold
                }

                // Breathing Glow Ring
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -4
                    radius: 52
                    color: "transparent"
                    border.color: Theme.accent
                    border.width: 1.5
                    opacity: avatarPulse.opacityVal

                    Item {
                        id: avatarPulse
                        property real opacityVal: 0.3
                        SequentialAnimation on opacityVal {
                            loops: Animation.Infinite
                            running: true
                            NumberAnimation { to: 0.8; duration: 1500; easing.type: Easing.InOutQuad }
                            NumberAnimation { to: 0.2; duration: 1500; easing.type: Easing.InOutQuad }
                        }
                    }
                }
            }

            Text {
                text: LockscreenService.username || "User"
                color: Theme.fg
                font.pixelSize: 20
                font.weight: Font.Bold
                Layout.alignment: Qt.AlignHCenter
            }
        }

        Item { Layout.preferredHeight: 4 }

        // 3. Elegant Glass Input Card with Animated Typing Dots
        Rectangle {
            id: cardContainer
            Layout.fillWidth: true
            implicitHeight: cardLayout.implicitHeight + 36
            radius: 20
            color: Theme.isDark ? Qt.rgba(30/255, 30/255, 46/255, 0.65) : Qt.rgba(240/255, 240/255, 245/255, 0.75)
            border.color: LockscreenService.authFailed ? Theme.red : (secretInput.activeFocus ? Theme.accent : Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.18))
            border.width: LockscreenService.authFailed ? 2 : (secretInput.activeFocus ? 2 : 1)

            Behavior on border.color { ColorAnimation { duration: 180 } }

            ColumnLayout {
                id: cardLayout
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 18
                spacing: 14

                // Password Row: Input Field + Submit Button
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    // Lock Icon
                    Text {
                        text: "🔒"
                        font.pixelSize: 18
                        Layout.alignment: Qt.AlignVCenter
                    }

                    // Password Visual Placeholder / Input Area
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 44
                        radius: 12
                        color: Qt.rgba(0, 0, 0, 0.25)
                        border.color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.1)

                        // Empty State Placeholder Text
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 16
                            visible: LockscreenService.typedCount === 0 && !LockscreenService.isAuthenticating
                            text: "Type password to unlock..."
                            color: Theme.comment
                            font.pixelSize: 14
                        }

                        // Authenticating Spinner / Status Text
                        Text {
                            anchors.centerIn: parent
                            visible: LockscreenService.isAuthenticating
                            text: "Verifying password..."
                            color: Theme.accent
                            font.pixelSize: 14
                            font.weight: Font.Medium
                        }

                        // ANIMATED TYPING DOTS (Shows WHEN and HOW MANY letters are typed)
                        Row {
                            anchors.centerIn: parent
                            spacing: 10
                            visible: LockscreenService.typedCount > 0 && !LockscreenService.isAuthenticating

                            Repeater {
                                model: LockscreenService.typedCount

                                Rectangle {
                                    id: dot
                                    width: 14
                                    height: 14
                                    radius: 7
                                    color: index === LockscreenService.typedCount - 1 ? Theme.accent : Theme.fg

                                    Behavior on color { ColorAnimation { duration: 120 } }

                                    // Spawn Bounce & Pulse Animation for each character typed
                                    scale: 1.0
                                    SequentialAnimation on scale {
                                        running: true
                                        NumberAnimation { from: 0.2; to: 1.4; duration: 120; easing.type: Easing.OutQuad }
                                        NumberAnimation { from: 1.4; to: 1.0; duration: 100; easing.type: Easing.OutBounce }
                                    }

                                    // Inner Glow Core
                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: 6
                                        height: 6
                                        radius: 3
                                        color: "#ffffff"
                                    }
                                }
                            }
                        }

                        // Focus Click Area
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                root.forceActiveFocus()
                                secretInput.forceActiveFocus()
                            }
                        }
                    }

                    // Submit / Unlock Arrow Button
                    Rectangle {
                        width: 44
                        height: 44
                        radius: 12
                        color: submitMouse.containsMouse ? Theme.accent : Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.25)
                        border.color: Theme.accent

                        Behavior on color { ColorAnimation { duration: 120 } }

                        Text {
                            anchors.centerIn: parent
                            text: "➔"
                            color: submitMouse.containsMouse ? "#ffffff" : Theme.accent
                            font.pixelSize: 18
                            font.weight: Font.Bold
                        }

                        MouseArea {
                            id: submitMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: LockscreenService.submitPassword()
                        }
                    }
                }

                // Dynamic Typing Status / Letter Counter & Feedback Message
                RowLayout {
                    Layout.fillWidth: true

                    // Typing Letter Counter Badge (Shows EXACT count of letters typed)
                    Rectangle {
                        implicitWidth: counterText.implicitWidth + 16
                        implicitHeight: 24
                        radius: 12
                        color: LockscreenService.typedCount > 0 ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.2) : "transparent"
                        visible: LockscreenService.typedCount > 0

                        Behavior on color { ColorAnimation { duration: 150 } }

                        Text {
                            id: counterText
                            anchors.centerIn: parent
                            text: `⌨️ ${LockscreenService.typedCount} ${LockscreenService.typedCount === 1 ? 'letter' : 'letters'} typed`
                            color: Theme.accent
                            font.pixelSize: 11
                            font.weight: Font.Bold
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // Auth Error Message Display
                    Text {
                        text: LockscreenService.authErrorMsg
                        color: Theme.red
                        font.pixelSize: 12
                        font.weight: Font.Bold
                        visible: LockscreenService.authFailed
                    }
                }
            }
        }

        Item { Layout.preferredHeight: 14 }

        // 4. Session Action Buttons (Power & Unlock)
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 16

            // Suspend Button
            Rectangle {
                implicitWidth: 110
                implicitHeight: 38
                radius: 10
                color: suspendMouse.containsMouse ? Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.15) : Qt.rgba(0, 0, 0, 0.3)
                border.color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.15)

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 6
                    Text { text: "🌙"; font.pixelSize: 13 }
                    Text { text: "Sleep"; color: Theme.fg; font.pixelSize: 12; font.weight: Font.Medium }
                }

                MouseArea {
                    id: suspendMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        Quickshell.execDetached(["systemctl", "suspend"])
                    }
                }
            }

            // Reboot Button
            Rectangle {
                implicitWidth: 110
                implicitHeight: 38
                radius: 10
                color: rebootMouse.containsMouse ? Qt.rgba(Theme.orange.r, Theme.orange.g, Theme.orange.b, 0.25) : Qt.rgba(0, 0, 0, 0.3)
                border.color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.15)

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 6
                    Text { text: "🔄"; font.pixelSize: 13 }
                    Text { text: "Restart"; color: Theme.fg; font.pixelSize: 12; font.weight: Font.Medium }
                }

                MouseArea {
                    id: rebootMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: SessionService.reboot()
                }
            }

            // Shutdown Button
            Rectangle {
                implicitWidth: 110
                implicitHeight: 38
                radius: 10
                color: powerMouse.containsMouse ? Qt.rgba(Theme.red.r, Theme.red.g, Theme.red.b, 0.25) : Qt.rgba(0, 0, 0, 0.3)
                border.color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.15)

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 6
                    Text { text: "⚡"; font.pixelSize: 13 }
                    Text { text: "Power Off"; color: Theme.fg; font.pixelSize: 12; font.weight: Font.Medium }
                }

                MouseArea {
                    id: powerMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: SessionService.shutdown()
                }
            }
        }
    }
}
