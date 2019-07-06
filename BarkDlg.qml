import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.3
import QtQuick.Dialogs 1.3
import Qt.labs.settings 1.0

Dialog {
    id: root
    standardButtons: StandardButton.Ok | StandardButton.Cancel
    title:  qsTr("Bark away")

    property int dlg_width: mainWindow.width > 300 ? 300 : mainWindow.width
    property int dlg_height: mainWindow.height > 350 ? 350 : mainWindow.height
    width: dlg_width
    height: dlg_height

    Rectangle {
        anchors.fill: parent
        color: "black"
    }

    ColumnLayout {
        spacing: 4
        anchors.fill: parent

        TextArea {
            id: bark
            Layout.fillHeight: true
            Layout.minimumHeight: 30
            Layout.minimumWidth: 3
            Layout.fillWidth: true
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            clip: true

        }
    }

    onAccepted: {

        var data = {
            type: 'bark',
            text: bark.text,
            image: null
        }

        mainWindow.bark(data)
        destroy();
    }

    onRejected: {
        destroy();
    }
}
