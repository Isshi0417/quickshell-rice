import QtQuick
import "../theme"

Item {
    id: root
    property var historyData: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    property color barColor: Theme.accent
    property int maxVal: 100
    property bool autoScale: true

    readonly property real effectiveMax: {
        if (!autoScale || !historyData || historyData.length === 0) return maxVal
        let maxSeen = 0
        for (let i = 0; i < historyData.length; i++) {
            if (historyData[i] > maxSeen) maxSeen = historyData[i]
        }
        return Math.max(15, maxSeen)
    }

    implicitHeight: 22
    implicitWidth: 120

    Row {
        anchors.fill: parent
        spacing: 2

        Repeater {
            model: 15

            Rectangle {
                id: barContainer
                width: Math.max(2, (root.width - (14 * 2)) / 15)
                height: root.height
                color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.5)
                radius: 2

                property real val: {
                    if (root.historyData && root.historyData.length > 0) {
                        let idx = root.historyData.length - 15 + index
                        if (idx >= 0 && idx < root.historyData.length) {
                            return root.historyData[idx]
                        }
                    }
                    return 0
                }

                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: Math.max(2, parent.height * Math.min(1.0, barContainer.val / Math.max(1.0, root.effectiveMax)))
                    color: root.barColor
                    radius: 2

                    Behavior on height {
                        NumberAnimation { duration: 400; easing.type: Easing.OutQuad }
                    }
                }
            }
        }
    }
}
