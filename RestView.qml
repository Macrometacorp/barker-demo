import QtQuick 2.12
import QtQuick.Controls 2.12
import Qt.labs.settings 1.0
import QtWebSockets 1.1

Item {
    id: root
    //anchors.fill: parent
    property string query: null
    property var bind: null
    property string auth:  `Bearer ${mainWindow.jwt}`
    property string apiurl:  mainWindow.api
    property string method: 'POST'
    property alias delegate: list.delegate

    Component.onCompleted: {
        root.runQuery()
    }

    ListModel {
        id: data
    }

    ListView {
        id: list
        anchors.fill: parent
        model: data
    }

    function runQuery() {
        data.clear()
//        if (!apiurl) {
//            apiurl = mainWindow.api
//        }
//        if (!auth) {
//            auth = `Bearer ${mainWindow.jwt}`
//        }

        var req = `${apiurl}/cursor`;
        if (query) {
            var body = {
                bindVars: bind,
                query: query
            }
        }

        var cli = new XMLHttpRequest();
        cli.onreadystatechange = function() {
            console.log(`REST state change: ${cli.readyState}`)
            if (cli.readyState === XMLHttpRequest.DONE) {
                if (cli.status === 201) {
                    var d = JSON.parse(cli.responseText );
                    for(var r in d.result) {
                        data.append(d.result[r]);
                    }
                } else {
                    console.log(`Query failed: ${req}`)
                    popup.text = qsTr("Error ") + `${cli.status} ${cli.statusText} ${cli.responseText}`
                    popup.open()
                }
                busy.running = false
            }
        }

        cli.open(method, req, true);
        cli.setRequestHeader('Content-type', 'application/json')
        cli.setRequestHeader('Accept', 'application/json')
        if (auth) {
            cli.setRequestHeader('Authorization', auth)
        }

        console.log(`REST request: : ${req}`)
        cli.send(JSON.stringify(body))
        busy.running = true
    }

    Popup {
        id: popup
        padding: 20
        anchors.centerIn: parent
        modal: true
        property var text: null
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        contentItem: Text {
            text: popup.text
        }
    }

    BusyIndicator {
        id: busy
        running: false
        anchors.centerIn: parent
    }
}
