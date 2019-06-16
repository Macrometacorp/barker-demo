import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.3
import QtQuick.Dialogs 1.3
import Qt.labs.settings 1.0

Dialog {
    id: root
    standardButtons: StandardButton.Ok | StandardButton.Cancel
    title:  qsTr("Create a new user account")

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

        GridLayout {
            id: fields
            rowSpacing: 4
            rows: 3
            flow: GridLayout.TopToBottom

            Label { font.pointSize: 9; text: qsTr("Name")}
            Label { font.pointSize: 9; text: qsTr("Password")}
            Label { font.pointSize: 9; text: qsTr("avatar")}

            TextField {
                id: name
                Layout.fillWidth: true
            }

            TextField {
                id: passwd
                Layout.fillWidth: true
            }

            TextField {
                id: avatar
                Layout.fillWidth: true
                placeholderText: "https://example.com/avatars/yours.jpg"
            }
        }

        Label { font.pointSize: 9; text: qsTr("About me")}

        TextArea {
            id: about
            Layout.fillHeight: true
            Layout.minimumHeight: 30
            Layout.minimumWidth: 3
            Layout.fillWidth: true
            clip: true
        }
    }

    onAccepted: {
        mainWindow.createUser( {
            "name": name.text,
            "passwd": passwd.text,
            "about": about.text,
            "avatar": avatar.text,
            "active": true })
        destroy();
    }

    onRejected: {
        destroy();
    }
}
