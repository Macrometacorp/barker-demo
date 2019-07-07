import QtQuick 2.0
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.3

ToolBar {
    id: root

    RowLayout {
        anchors.fill: parent
        ToolButton {
            text: qsTr("‹")
            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
            onClicked: mainWindow.stack.pop()
            enabled: mainWindow.stack.depth > 1
        }

        TextField {
            id: search
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            placeholderText: qsTr("Search term")
        }

        ToolButton {
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            icon.source: "qrc:///images/Vector_search_icon.svg"
            onClicked: mainWindow.search(search.text)
            enabled: search.text
        }

        ToolButton {
            text: qsTr("⋮")
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            onClicked: menu.open()

            Menu {
                id: menu

                MenuItem {
                    text: qsTr("Most nearby barkers")
                    onTriggered: {
                        mainWindow.showNearby(5)
                    }
                }

                MenuItem {
                    text: qsTr("I follow")
                    onTriggered: {
                        mainWindow.showFollowers('outbound', 1)
                    }
                }

                MenuItem {
                    text: qsTr("I follow and they follow")
                    onTriggered: {
                        mainWindow.showFollowers('outbound', 2)
                    }
                }

                MenuItem {
                    text: qsTr("Followers")
                    onTriggered: {
                        mainWindow.showFollowers('inbound', 1)
                    }
                }

                MenuItem {
                    text: qsTr("Followers an theirs")
                    onTriggered: {
                        mainWindow.showFollowers('inbound', 2)
                    }
                }
            }
        }
    }
}
