import QtQuick
import "../theme"

Rectangle {
    id: root

    property alias contentItem: container
    default property alias data: container.data

    color: Theme.bg
    radius: Theme.cornerRadius
    border.color: Theme.currentLine
    border.width: 1

    Item {
        id: container
        anchors.fill: parent
        anchors.margins: 4
    }
}
