import QtQuick 2.0
import QtQuick.Controls 2.5

Item {
    property ListView list: null
    anchors.margins: 8
    width: parent.width
    height: textarea.contentHeight + 12 + date.height

    Rectangle {
        id: textbox
        property int margin: 8
        anchors.fill: parent
        color: index == list.currentIndex ? "white" : "aliceblue"
        radius: 6
    }

    TextEdit {
        id: date
        x: 6
        anchors.top: parent.top
        anchors.margins: 2
        color: "darkgreen"
        text: when
    }

    TextEdit {
        id: textarea
        anchors.top: date.bottom
        anchors.left: textbox.left
        anchors.right: textbox.right
        anchors.margins: 6
        readOnly: true
        selectByMouse: true
        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
        text: bark ? bark : ""
        clip: true
    }

    MouseArea {
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        anchors.fill: parent
        onClicked: {
            list.currentIndex = index
        }

        onPressAndHold: {
            //cList.currentIndex = index
        }
    }

    // Barker is clickable and must overlay MouseArea
    Barker {
        anchors.margins: 2
        anchors.left: date.right
        anchors.top: parent.top
        value: barker
    }
}
