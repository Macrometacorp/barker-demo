import QtQuick 2.12
import QtQuick.Controls 2.12
import Qt.labs.settings 1.0
import QtWebSockets 1.1

RestView {
    id: root
    anchors.fill: parent

    delegate: ItemDelegate {
        text: `@${_key} ` + getText()
        width: root.width

        onClicked: {
            console.log("Clicked!")

            var component = Qt.createComponent("qrc:/UserView.qml")
            if (component.status !== Component.Ready) {
                if(component.status === Component.Error )
                    console.debug("Error:"+ component.errorString() );
                return;
            }
            var view = component.createObject(mainWindow, {
                userData: {_key: _key, about: about},
            });

            mainWindow.stack.push(view)
        }

        function getText() {
            if (typeof distance !== 'undefined') {
                return Math.round(distance) / 1000.0 + qsTr(' km away')
            }
            return about
        }
    }
}
