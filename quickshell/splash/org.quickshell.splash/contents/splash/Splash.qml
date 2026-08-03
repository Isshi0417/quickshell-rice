import QtQuick
import QtQuick.Layouts

Item {
    id: root
    width: 1920
    height: 1080

    property int stage: 0

    // Dynamic Theme Colors & User Name (read from JSON or fallback defaults)
    property color bgColor: "#1e1e2e"
    property color surfaceColor: "#181825"
    property color fgColor: "#cdd6f4"
    property color accentColor: "#cba6f7"
    property color subAccentColor: "#89b4fa"
    property string themeName: "QuickShell"
    property string userName: "User"

    // Load theme colors & user info on startup
    Component.onCompleted: {
        loadColors();
    }

    onStageChanged: {
        loadColors();
    }

    function loadColors() {
        try {
            var request = new XMLHttpRequest();
            request.open("GET", "file://" + pathOfConfigFile(), false);
            request.send(null);
            if (request.status === 200 || request.status === 0) {
                var json = JSON.parse(request.responseText);
                if (json.bg) bgColor = json.bg;
                if (json.surface) surfaceColor = json.surface;
                if (json.fg) fgColor = json.fg;
                if (json.accent) accentColor = json.accent;
                if (json.subAccent) subAccentColor = json.subAccent;
                if (json.variantName) themeName = json.variantName;
                if (json.userName) userName = json.userName;
            }
        } catch (e) {
            // Fallback gracefully
        }
    }

    function pathOfConfigFile() {
        return "/home/" + (typeof envUser !== "undefined" ? envUser : "sho") + "/.config/quickshell/theme/splash_colors.json";
    }

    // Rich Dark Background with dynamic theme color fill
    Rectangle {
        anchors.fill: parent
        color: bgColor

        // Ambient Glow Orb 1
        Rectangle {
            width: Math.min(root.width, root.height) * 0.7
            height: width
            radius: width / 2
            anchors.centerIn: parent
            color: Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.12)

            SequentialAnimation on scale {
                loops: Animation.Infinite
                NumberAnimation { from: 0.85; to: 1.15; duration: 3500; easing.type: Easing.InOutQuad }
                NumberAnimation { from: 1.15; to: 0.85; duration: 3500; easing.type: Easing.InOutQuad }
            }
        }

        // Ambient Glow Orb 2
        Rectangle {
            width: Math.min(root.width, root.height) * 0.5
            height: width
            radius: width / 2
            anchors.centerIn: parent
            color: Qt.rgba(subAccentColor.r, subAccentColor.g, subAccentColor.b, 0.08)

            SequentialAnimation on scale {
                loops: Animation.Infinite
                NumberAnimation { from: 1.15; to: 0.85; duration: 4500; easing.type: Easing.InOutQuad }
                NumberAnimation { from: 0.85; to: 1.15; duration: 4500; easing.type: Easing.InOutQuad }
            }
        }
    }

    // Center Content Card
    ColumnLayout {
        anchors.centerIn: parent
        spacing: 24

        // Animated Pulsing Badge
        Item {
            Layout.alignment: Qt.AlignHCenter
            width: 110
            height: 110

            // Outer Pulsing Ring
            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: "transparent"
                border.color: accentColor
                border.width: 3
                opacity: 0.8

                SequentialAnimation on scale {
                    loops: Animation.Infinite
                    NumberAnimation { from: 1.0; to: 1.3; duration: 2000; easing.type: Easing.InOutQuad }
                    NumberAnimation { from: 1.3; to: 1.0; duration: 2000; easing.type: Easing.InOutQuad }
                }

                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    NumberAnimation { from: 0.8; to: 0.15; duration: 2000; easing.type: Easing.InOutQuad }
                    NumberAnimation { from: 0.15; to: 0.8; duration: 2000; easing.type: Easing.InOutQuad }
                }
            }

            // Inner Glass Badge
            Rectangle {
                anchors.centerIn: parent
                width: 82
                height: 82
                radius: 41
                color: Qt.rgba(surfaceColor.r, surfaceColor.g, surfaceColor.b, 0.85)
                border.color: Qt.rgba(fgColor.r, fgColor.g, fgColor.b, 0.2)
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "❖"
                    font.pixelSize: 38
                    color: accentColor
                }
            }
        }

        // Welcome User Title
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "Welcome, " + userName
            font.pixelSize: 26
            font.bold: true
            font.family: "Outfit, Inter, Sans-Serif"
            color: fgColor
            opacity: 0.95
        }

        // Smooth Progress Bar
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            width: 260
            height: 6
            radius: 3
            color: Qt.rgba(surfaceColor.r, surfaceColor.g, surfaceColor.b, 0.9)
            border.color: Qt.rgba(fgColor.r, fgColor.g, fgColor.b, 0.12)
            border.width: 1
            clip: true

            Rectangle {
                id: progressBar
                height: parent.height
                radius: 3
                color: accentColor
                width: Math.min(parent.width, Math.max(12, (Math.max(1, root.stage) / 6.0) * parent.width))

                Behavior on width {
                    NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                }
            }
        }

        // Status Label
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: stage === 0 ? "Initializing Plasma..." :
                  stage === 1 ? "Loading System Services..." :
                  stage === 2 ? "Setting up Desktop..." :
                  stage === 3 ? "Loading Panels & Dock..." :
                  stage === 4 ? "Preparing Workspace..." : "Starting..."
            font.pixelSize: 13
            font.family: "Outfit, Inter, Sans-Serif"
            color: Qt.rgba(fgColor.r, fgColor.g, fgColor.b, 0.65)
        }
    }
}
