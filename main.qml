import QtQuick 2.12
import QtQuick.Controls 2.12
import Qt.labs.settings 1.0
import QtWebSockets 1.1

ApplicationWindow {
    id: mainWindow
    visible: true
    width: 640
    height: 480
    title: "Barfer"

    property int appState: 0 // 0 init, 1 have token, 2 connecting, 3 connected
    property string api: null
    property string authHeader: null
    property string wssUrl: null
    property var keys: ([])

    // Remember the windows position and size
    Settings {
        id: position
        property alias x: mainWindow.x
        property alias y: mainWindow.y
        property alias width: mainWindow.width
        property alias height: mainWindow.height
    }

    // Remember the
    Settings {
        id: user
        property string name: null
        property string passwd: null
    }

    Settings {
        id: app
        property string service: "http://127.0.0.1:8080"
    }

    ListModel {
        id: feed
    }

    Component.onCompleted: {
        if (user.name) {
            next();
        } else {
            // Create a user account
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
            model: feed
            delegate: ItemDelegate {
                text: `${when} ${barfer}: ${barf}`
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

                    next();

                } else {
                    popup.text = qsTr("Error when creating user: ") + cli.responseText
                    popup.exitOnClose = true
                }

                popup.open();
                busy.running = false
            }
        }

        cli.open('POST', `${app.service}/barfer/user`, true);
        cli.setRequestHeader('Content-type', 'application/json');
        cli.send(JSON.stringify(data))
        busy.running = true
    }

    function login() {
        var cli = new XMLHttpRequest();
        cli.onreadystatechange = function() {
            if (cli.readyState === XMLHttpRequest.DONE) {
                if (cli.status === 200) {

                    var data = JSON.parse(cli.responseText)

                    mainWindow.api= data.api
                    mainWindow.appState = 1
                    mainWindow.authHeader = `Authorization: Bearer ${data.jwt}`
                    mainWindow.wssUrl = data.wss

                    next();

                } else {
                    popup.text = qsTr("Error getting login token: ") + cli.responseText
                    popup.exitOnClose = true
                    popup.open()
                }

                busy.running = false
            }
        }

        cli.open('POST', `${app.service}/barfer/login`, true);
        cli.setRequestHeader('Content-type', 'application/json');
        cli.send(JSON.stringify({
            name: user.name,
            passwd: user.passwd
        }))
        busy.running = true
    }

    function next() {
        if (appState === 0) {
            login()
        } else if (appState === 1) {
            console.log("Activating websocket")
            ws.active = false;
            ws.active = true;
            appState = 2
        } else if (appState === 3) {
            // We are connected to the feed
        }
    }

    onAppStateChanged: {
        console.log(`New appstate: ${appState}`)
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

    WebSocket {
        id: ws
        url: mainWindow.wssUrl

        onStatusChanged: {
            console.log(`Wss Status: ${status}`)
            switch(status) {
            case WebSocket.Connecting:
                console.log(`websocket connecting to "${url}"`)
                busy.running = true
                mainWindow.appState = 2
                break
            case WebSocket.Open:
                busy.running = false
                mainWindow.appState = 3
                break
            case WebSocket.Error:
                console.log(`websocket error! ${errorString}`)
                busy.running = false
                if (mainWindow.appState === 3 || mainWindow.appState == 2) {
                    mainWindow.appState = 1
                }
                break
            case WebSocket.Closed:
                ; // Do nothing
            }
            next()
        }

        onTextMessageReceived: (message) => {
            console.log(`Wss onTextMessageReceived: ${message}`)
            const msg = JSON.parse(message)
            const payload = Qt.atob(msg.payload)
            var barf = JSON.parse(payload)
            barf.when = new Date(barf.timestamp).toLocaleString(Qt.locale('en'), Locale.ShortFormat);

            // We keep all the keys we have loaded in 'keys to avoid
            // duplicates when re-connecting. We could clear the feed
            // when re-connecting as well, but that would cause flickering.
            if (!keys.includes(barf._key)) {
                keys.push(barf._key)
                feed.insert(0, barf)
            }
        }
    }
}
