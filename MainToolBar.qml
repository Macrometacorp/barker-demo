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
        }
    }
}
