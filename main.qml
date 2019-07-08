import QtQuick 2.12
import QtQuick.Controls 2.12
import Qt.labs.settings 1.0
import QtWebSockets 1.1
import QtPositioning 5.12

ApplicationWindow {
    id: mainWindow
    visible: true
    width: 640
    height: 480
    title: "barker"

    property int appState: App.State.Init // 0 init, 1 have token, 2 connecting to feed,
        // 3 connecting to websocket 4 connected, 5 barking
    property string api: ''
    property string authHeader: ''
    property string wssUrl: ''
    property var keys: ([])
    property string jwt: ''
    property var queue: ([])
    property alias  mainView: listView
    property alias stack: stackView

    header: MainToolBar {
        id: mainToolBar
        width: parent.width
    }

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
        property string name: ''
        property string passwd: ''
    }

    Settings {
        id: app
        property string service: "https://barker.lastviking.eu"
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


    StackView {
        id: stackView
        anchors.fill: parent
        initialItem:
            ListView {
                id: listView
                anchors.fill: parent
                model: feed
                spacing: 4
                clip: true
                ScrollBar.vertical: ScrollBar { id: scrollbar}
                delegate: FeedDelegate {
                    list: listView
                }
            }
    }

    RoundButton {
        id: roundButton
        width: 60
        height: 60
        radius: width / 2
        Image {
            width: 30
            height: 30
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter
            id: icon
            source: "qrc:///images/Barking_Dog_-_The_Noun_Project.svg"
        }
        anchors.bottomMargin: 6
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        font.bold: true
        highlighted: true
        enabled: mainWindow.appState === App.State.Connected

        onClicked: {
            var component = Qt.createComponent("qrc:/BarkDlg.qml")
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

    function search(term) {
        // Search for about

        if (term.charAt(0) == '@') {
            var lowerTerm = term.toLowerCase()
            var query = 'for u in users filter u._key == @name return u'
            var bind =  {"name": term.substr(1)}
        } else {
            // Search in about field
            var lowerTerm = term.toLowerCase()
            var query = 'for u in users filter contains(lower(u.about), lower(@phrase)) return u'
            var bind =  {"phrase": term}
        }

        openUserList(query, bind)
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

        cli.open('POST', `${app.service}/barker/user`, true);
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
                    mainWindow.appState = App.State.HaveToken
                    mainWindow.authHeader = `Authorization: Bearer ${data.jwt}`
                    mainWindow.jwt = data.jwt
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

        cli.open('POST', `${app.service}/barker/login`, true);
        cli.setRequestHeader('Content-type', 'application/json');
        cli.send(JSON.stringify({
            name: user.name,
            passwd: user.passwd
        }))
        busy.running = true
    }


    function bark(data) {
        queue.push(data)
    }

    function _bark(data) {
        data.barker = user.name
        data.jwt = jwt

        var cli = new XMLHttpRequest();
        cli.onreadystatechange = function() {
            console.log(`bark state change: ${cli.readyState}`)
            if (cli.readyState === XMLHttpRequest.DONE) {
                if (cli.status === 202) {
                    popup.text = qsTr("You successfully barked!")
                } else {
                    popup.text = qsTr("Error when barking: ") + cli.responseText
                }
                popup.open();
                busy.running = false

                if (mainWindow.appState === App.State.Barking) {
                    mainWindow.appState = App.State.Connected
                }
            }
        }

        var url = `${app.service}/barker/bark`

        console.log(`Barking to url: ${url}`)

        cli.open('POST', url, true);
        cli.setRequestHeader('Content-type', 'application/json');
        cli.send(JSON.stringify(data))
        busy.running = true
        mainWindow.appState = App.State.Barking
    }

    function follow(key) {
        var cli = new XMLHttpRequest();
        cli.onreadystatechange = function() {
            if (cli.readyState === XMLHttpRequest.DONE) {
                if (cli.status >= 200 && cli.status < 300 ) {
                    popup.text = qsTr(`You successfully follows ${key}`)
                } else {
                    popup.text = qsTr("Error when follwing: ") + cli.responseText
                }
                popup.open();
            }
        }

        var url = `${api}/document/follow`;
        var data = {
            _from: `users/${user.name}`,
            _to: `users/${key}`,
            vertex: user.name
        }

        cli.open('POST', url, true);
        cli.setRequestHeader('Content-type', 'application/json');
        cli.setRequestHeader('Accept', 'application/json');
        cli.setRequestHeader('Authorization', `Bearer ${jwt}`);
        cli.send(JSON.stringify(data))
    }

    function unfollow(key) {
        var cli = new XMLHttpRequest();
        cli.onreadystatechange = function() {
            if (cli.readyState === XMLHttpRequest.DONE) {
                if (cli.status >= 200 && cli.status < 300 ) {
                    popup.text = qsTr(`You successfully unfollowed ${key}`)
                } else {
                    popup.text = qsTr("Error when unfollowing: ") + cli.responseText
                }
                popup.open();
            }
        }

        var url = `${api}/cursor`;
        var data = {
            bindVars: {from: `users/${user.name}`, to: `users/${key}`},
            query: 'for f in follow filter f._from == @from and f._to == @to remove f in follow'
        }

        cli.open('POST', url, true);
        cli.setRequestHeader('Content-type', 'application/json');
        cli.setRequestHeader('Accept', 'application/json');
        cli.setRequestHeader('Authorization', `Bearer ${jwt}`);
        cli.send(JSON.stringify(data))
        console.log('sending data: ' + JSON.stringify(data))
    }

    function showFollowers(direction, level) {
        // Search in about field
        var query = 'with users
    for follower in 1..@level ' + direction + ' @who follow
        filter follower.active == true
        return distinct follower'
        var bind =  {who: `users/${user.name}`, level : level}

        openUserList(query, bind)
    }

    function openUserList(query, bind) {
        var component = Qt.createComponent("qrc:/UserList.qml")
        if (component.status !== Component.Ready) {
            if(component.status === Component.Error )
                console.debug("Error:"+ component.errorString() );
            return;
        }
        var view = component.createObject(mainWindow, {
            parent : mainWindow,
            query: query,
            bind: bind
        });

        stack.push(view)
    }

    function showUser(name) {
        openUserList('for u in users filter u._key == @name return u', {name: name})
    }

    function next() {
        if (appState === App.State.Init) {
            login()
        } else if (appState === App.State.HaveToken) {
            console.log("Fetching feed")
            fetchFeed()
        } else if (appState === App.State.HaveFeed) {
            console.log("Activating websocket")
            ws.active = false;
            ws.active = true;
            appState = App.State.ConnectToStream
        } else if (appState === App.State.Connected) {
            // We are connected to the feed
        }
    }

    function fetchFeed() {
        feed.clear()
        var req = `${app.service}/barker/feed`
        appState = App.State.ConnectToFeed
        var cli = new XMLHttpRequest();
        cli.onreadystatechange = function() {
            console.log(`REST state change: ${cli.readyState}`)
            if (cli.readyState === XMLHttpRequest.DONE) {
                if (cli.status === 200) {
                    var d = JSON.parse(cli.responseText );
                    for(var r in d.result) {
                        feed.append(d.result[r]);
                        keys.push(r._key)
                    }
                    appState = App.State.HaveFeed
                    next()
                } else {
                    console.log(`Query failed: ${req}`)
                    popup.text = qsTr("Failed to fetch feed ") + `${cli.status} ${cli.statusText} ${cli.responseText}`
                    popup.exitOnClose = true
                    popup.open()
                }
                busy.running = false
            }
        }

//        var req = `${api}/cursor`;
//        cli.open('POST', req, true);
//        cli.setRequestHeader('Content-type', 'application/json')
//        cli.setRequestHeader('Accept', 'application/json')
//        if (authHeader) {
//            cli.setRequestHeader('Authorization', authHeader)
//        }

//        console.log(`REST request: : ${req}`)
//        var body = {
//            bindVars: {who: `users/${user.name}`, num: 20},
//            query: 'with users
//              for f in 0..1 outbound @who follow
//                filter f.active == true
//                for b in barks
//                    filter f._key == b.barker
//                    sort b.timestamp desc
//                    limit @num
//                    return b'
//        }
//        cli.send(JSON.stringify(body))
        cli.open('POST', req, true);
        cli.setRequestHeader('Content-type', 'application/json');
        cli.send(JSON.stringify({
            name: user.name,
        }))
        busy.running = true
    }

    function showNearby(num) {
        openUserList(
        'for loc in NEAR(locations, @lat, @long, @num, "distance")'
        + ' filter loc._key != @me'
        + '  for u in users'
        + '  filter u._key == loc._key'
        + '  filter u.active == true'
        + '  sort loc.distance'
        + '  return {_key: u._key, about: u.about, avatar: u.avatar, distance: loc.distance}'
        , {lat: pos.position.coordinate.latitude,
           long: pos.position.coordinate.longitude,
           num: num,
           me: user.name
        })
    }

    function updateLocation(latitude, longitude) {
        if (mainWindow.appState !== App.State.Connected) {
            // Only do this when the app is logged in and idle
            return
        }

        var cli = new XMLHttpRequest();
        cli.onreadystatechange = function() {
            if (cli.readyState === XMLHttpRequest.DONE) {
                if (cli.status >= 200 && cli.status < 300 ) {
                    console.log('You successfully updated your location')
                } else {
                    popup.text = qsTr("Error when sending location: ") + cli.responseText
                    popup.open();
                }
            }
        }

        var url = `${api}/document/locations`;
        var data = {
            _key: `${user.name}`,
            location: [longitude,latitude]
        }

        cli.open('POST', url, true);
        cli.setRequestHeader('Content-type', 'application/json');
        cli.setRequestHeader('Accept', 'application/json');
        cli.setRequestHeader('Authorization', `Bearer ${jwt}`);
        cli.send(JSON.stringify(data))
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

    function ack(msgid) {

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
                mainWindow.appState = App.State.ConnectToStream
                break
            case WebSocket.Open:
                busy.running = false
                mainWindow.appState = App.State.Connected
                break
            case WebSocket.Error:
                console.log(`websocket error! ${errorString}`)
                busy.running = false
                if (mainWindow.appState === App.State.ConnectToStream
                        || mainWindow.appState === App.State.Connected ) {
                    mainWindow.appState = App.State.HaveFeed
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
            var bark = JSON.parse(payload)
            //bark.when = new Date(bark.timestamp).toLocaleString(Qt.locale('en'), Locale.ShortFormat);

            // We keep all the keys we have loaded in 'keys to avoid
            // duplicates, as we first get the feed from the database and
            // then subscribe to updates here.
            if (!keys.includes(bark._key)) {
                keys.push(bark._key)
                feed.insert(0, bark)
            }

            // Acknowledge
            sendTextMessage(JSON.stringify({messageId: msg.messageId}))
        }
    }

    Timer {
        id: timer
        interval: 1000
        running: mainWindow.appState === App.State.Connected
        repeat: true
        onTriggered: {
            if (queue.length) {
                _bark(queue.pop())
            }
        }
    }

    PositionSource {
        id: pos
        updateInterval: 60000
        active: mainWindow.appState === App.State.Connected

        onPositionChanged: {
            var coord = pos.position.coordinate;
            console.log("Coordinate:", coord.longitude, coord.latitude);

            mainWindow.updateLocation(pos.position.coordinate.latitude,
                                      pos.position.coordinate.longitude)
        }
    }
}

