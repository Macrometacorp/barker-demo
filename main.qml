import QtQuick 2.12
import QtQuick.Controls 2.12
import Qt.labs.settings 1.0

ApplicationWindow {
    id: mainWindow
    visible: true
    width: 640
    height: 480
    title: "Barfer"

    // Remember the windows position and size
    Settings {
        id: position
        property alias x: mainWindow.x
        property alias y: mainWindow.y
        property alias width: mainWindow.width
        property alias height: mainWindow.height
    }

    Settings {
        id: user
        property string name: null
        property string passwd: null
    }

    Settings {
        id: api
        property string api: "https://jgaa-europe-west1.eng1.macrometa.io"
        property string service: "http://127.0.0.1:8080"
    }

    Component.onCompleted: {
        if (!user.name) {
            var component = Qt.createComponent("qrc:/CreateUserDlg.qml")
            if (component.status !== Component.Ready) {
                if(component.status === Component.Error )
                    console.debug("Error:"+ component.errorString() );
                return;
            }
            var dlg = component.createObject(mainWindow, {
                parent : mainWindow
            });
            dlg.open()
        }
    }

    ScrollView {
        anchors.fill: parent

        ListView {
            width: parent.width
            model: null
            delegate: ItemDelegate {
                text: "Item " + (index + 1)
                width: parent.width
            }
        }
    }

    function createUser(data) {
        var cli = new XMLHttpRequest();
        cli.onreadystatechange = function() {
            if (cli.readyState === XMLHttpRequest.DONE) {
                if (cli.status === 202) {
                    popup.text = qsTr("Your account was successfully created!")

                    user.name = data.name
                    user.passwd = data.passwd

                    // TODO: Refresh feed

                } else {
                    popup.text = qsTr("Error: ") + cli.responseText
                    popup.exitOnClose = true
                }

                popup.open();
                busy.running = false
            }
        }

        cli.open('POST', `${api.service}/barfer/user`, true);
        cli.setRequestHeader('Content-type', 'application/json');
        cli.send(JSON.stringify(data))
        busy.running = true
    }

    BusyIndicator {
        id: busy
        running: false
        anchors.centerIn: parent
    }

    Popup {
        id: popup
        padding: 20
        anchors.centerIn: parent
        modal: true
        property var text: null
        property bool exitOnClose: false
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        contentItem: Text {
            text: popup.text
        }

        onClosed: {
            if (exitOnClose) {
                mainWindow.close()
            }
        }
    }
}
