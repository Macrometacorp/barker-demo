import QtQuick 2.0

TextEdit {
    id: root
    anchors.margins: 4
    property var value: null
    text: `@${value}`
    color: "blue"

    MouseArea {
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        anchors.fill: parent
        onClicked: {
            mainWindow.showUser(root.value)
        }
    }
}
