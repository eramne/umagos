import QtQuick 2.14
import QtQuick.Window 2.14
import QtQuick.Controls 2.3
import QtQuick.Dialogs 1.0
import QtQuick.Layouts 1.15
import QtQml.Models 2.2
import umagos.components 1.0
import umagos.pages 1.0

Item {
    id: window
    width: 640
    height: 480 + bar.height
    visible: true

    Rectangle {
        anchors.fill: parent
        color: "white"

        MouseArea {
            anchors.fill: parent
            propagateComposedEvents: true
            onClicked: {
                window.forceActiveFocus();
            }
        }

        Shortcut {
            sequence: StandardKey.Cancel
            onActivated: {
                window.forceActiveFocus();
            }
        }
    }

    TabBar {
        id: bar
        width: parent.width
        TabButton {
            width: implicitWidth
            text: qsTr("Image Conversion")
        }
        TabButton {
            width: implicitWidth
            text: qsTr("Test")
        }
    }

    StackLayout {
        id: pageview
        //anchors.fill: parent
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.top: bar.bottom
        currentIndex: bar.currentIndex

        ImageFormatConvertPage {
            objectName: "imageFormatConvertPage"
        }

        Item {
            Text {
                anchors.centerIn: parent
                text: "Test page"
            }
        }
    }
}


