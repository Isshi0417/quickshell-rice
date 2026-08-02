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
                    onTriggered: {
                        let date = new Date()
                        let h = date.getHours().toString().padStart(2, '0')
                        let m = date.getMinutes().toString().padStart(2, '0')
                        let s = date.getSeconds().toString().padStart(2, '0')
                        clockText.text = `${h}:${m}:${s}`
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
                    text: LockscreenService.username ? LockscreenService.username.charAt(0).toUpperCase() : "U"
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

        // 3. Opaque Solid Input Card with Animated Typing Dots & Session Controls
        Rectangle {
            id: cardContainer
            Layout.fillWidth: true
            implicitHeight: cardLayout.implicitHeight + 36
            radius: 24
            color: Theme.surface
            border.color: LockscreenService.authFailed ? Theme.red : (secretInput.activeFocus ? Theme.accent : Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.22))
            border.width: LockscreenService.authFailed ? 2 : (secretInput.activeFocus ? 2 : 1)

            Behavior on border.color { ColorAnimation { duration: 180 } }

            ColumnLayout {
                id: cardLayout
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 18
                spacing: 16

                // Centered Password Input Field
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 48
                    radius: 14
                    color: Theme.bg
                    border.color: secretInput.activeFocus ? Theme.accent : Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.2)

                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    // Empty State Placeholder Text (Centered)
                    Text {
                        anchors.centerIn: parent
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

                    ListModel {
                        id: dotsModel
                    }

                    Connections {
                        target: LockscreenService
                        function onTypedCountChanged() {
                            let targetCount = LockscreenService.typedCount
                            while (dotsModel.count < targetCount) {
                                dotsModel.append({ "id": dotsModel.count })
                            }
                            while (dotsModel.count > targetCount) {
                                dotsModel.remove(dotsModel.count - 1)
                            }
                        }
                    }

                    // ANIMATED TYPING DOTS (Centered sliding dot array with add/remove/displaced transitions)
                    Item {
                        id: dotsContainer
                        anchors.centerIn: parent
                        implicitWidth: Math.min(320, dotsModel.count * 26)
                        implicitHeight: 20
                        visible: dotsModel.count > 0 && !LockscreenService.isAuthenticating

                        Behavior on implicitWidth {
                            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
                        }

                        ListView {
                            id: dotsView
                            anchors.centerIn: parent
                            width: Math.min(dotsContainer.implicitWidth, count * 26)
                            height: 20
                            orientation: ListView.Horizontal
                            spacing: 12
                            interactive: false
                            model: dotsModel

                            add: Transition {
                                ParallelAnimation {
                                    NumberAnimation { property: "scale"; from: 0.1; to: 1.0; duration: 250; easing.type: Easing.OutBack; easing.overshoot: 1.6 }
                                    NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; duration: 200; easing.type: Easing.OutCubic }
                                }
                            }

                            remove: Transition {
                                ParallelAnimation {
                                    NumberAnimation { property: "scale"; from: 1.0; to: 0.1; duration: 200; easing.type: Easing.InCubic }
                                    NumberAnimation { property: "opacity"; from: 1.0; to: 0.0; duration: 200; easing.type: Easing.OutCubic }
                                }
                            }

                            displaced: Transition {
                                NumberAnimation { properties: "x,y"; duration: 220; easing.type: Easing.OutCubic }
                            }

                            delegate: Item {
                                width: 14
                                height: 14

                                Rectangle {
                                    id: dot
                                    anchors.fill: parent
                                    radius: 7
                                    color: index === dotsModel.count - 1 ? Theme.accent : Theme.fg

                                    Behavior on color { ColorAnimation { duration: 180 } }

                                    // Inner Glow Core
                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: 6
                                        height: 6
                                        radius: 3
                                        color: "#ffffff"
                                        opacity: index === dotsModel.count - 1 ? 1.0 : 0.6
                                    }
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

                // Dynamic Auth Error Feedback Message
                RowLayout {
                    Layout.fillWidth: true
                    visible: LockscreenService.authFailed

                    Item { Layout.fillWidth: true }

                    Text {
                        text: LockscreenService.authErrorMsg
                        color: Theme.red
                        font.pixelSize: 12
                        font.weight: Font.Bold
                    }

                    Item { Layout.fillWidth: true }
                }

                // Prominent, Large Session Action Buttons (Right underneath Password Input)
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    // Suspend / Sleep Button
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 48
                        radius: 12
                        color: suspendMouse.containsMouse ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.25) : Theme.bg
                        border.color: suspendMouse.containsMouse ? Theme.accent : Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.2)

                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 8
                            Text { text: "󰒲"; font.pixelSize: 18; font.family: "JetBrainsMono Nerd Font, Symbols Nerd Font, CaskaydiaCove Nerd Font, Sans-Serif"; color: Theme.accent }
                            Text { text: "Sleep"; color: Theme.fg; font.pixelSize: 14; font.weight: Font.SemiBold }
                        }

                        MouseArea {
                            id: suspendMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: Quickshell.execDetached(["systemctl", "suspend"])
                        }
                    }

                    // Reboot / Restart Button
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 48
                        radius: 12
                        color: rebootMouse.containsMouse ? Qt.rgba(Theme.orange.r, Theme.orange.g, Theme.orange.b, 0.25) : Theme.bg
                        border.color: rebootMouse.containsMouse ? Theme.orange : Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.2)

                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 8
                            Text { text: "󰜉"; font.pixelSize: 18; font.family: "JetBrainsMono Nerd Font, Symbols Nerd Font, CaskaydiaCove Nerd Font, Sans-Serif"; color: Theme.orange }
                            Text { text: "Restart"; color: Theme.fg; font.pixelSize: 14; font.weight: Font.SemiBold }
                        }

                        MouseArea {
                            id: rebootMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: SessionService.reboot()
                        }
                    }

                    // Shutdown / Power Off Button
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 48
                        radius: 12
                        color: powerMouse.containsMouse ? Qt.rgba(Theme.red.r, Theme.red.g, Theme.red.b, 0.25) : Theme.bg
                        border.color: powerMouse.containsMouse ? Theme.red : Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.2)

                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 8
                            Text { text: "󰐥"; font.pixelSize: 18; font.family: "JetBrainsMono Nerd Font, Symbols Nerd Font, CaskaydiaCove Nerd Font, Sans-Serif"; color: Theme.red }
                            Text { text: "Power Off"; color: Theme.fg; font.pixelSize: 14; font.weight: Font.SemiBold }
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
    }
}
