import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls 1.4

Item {
    id: root
    property var userData: null
    property string name: null
    anchors.fill: parent

    Component.onCompleted: {
        if (name && !userData) {

        }
    }

    Text {
        id: barker
        color: "#5ddff0"
        text: `@${userData._key}`
    }

    Text {
        id: about
        text: userData.about
        anchors.top: barker.bottom
        anchors.topMargin: 0
        width: parent.width
        color: "#62f046"
    }

    RowLayout {
        id: follow
        anchors.top: about.bottom
        spacing: 6

        Button {
            text: "Follow"
            onClicked: {
                mainWindow.follow(userData._key)
            }
        }

        Button {
            text: "Unfollow"
            onClicked: {
                mainWindow.unfollow(userData._key)
            }
        }
    }

    Text {
        id: barklabel
        color: "yellow";
        text: `Barks from ${root.userData._key}`
        anchors.top: follow.bottom
        anchors.topMargin: 6
    }

    RestView {
        id: list
        anchors.right: parent.right
        anchors.left: parent.left
        anchors.leftMargin: 0
        anchors.bottom: parent.bottom
        anchors.top: barklabel.bottom
        anchors.topMargin: 3
        query: `for b in barks filter b.barker == "${root.userData._key}" sort b.timestamp desc return b`
        bind: {}
        delegate: FeedDelegate {
            list: list
        }
    }

    function when(ts) {
        return new Date(ts).toLocaleString(Qt.locale('en'), Locale.ShortFormat);
    }
}
