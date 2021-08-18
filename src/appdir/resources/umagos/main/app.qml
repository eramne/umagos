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
    width: 640 + vtabbar.width
    height: 480 + htabbar.height
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
        id: vtabbar
        height: parent.height
        width: 100
        TabButton {
            width: parent.width
            text: qsTr("Image Tools")
        }
        TabButton {
            width: parent.width
            text: qsTr("Video Tools")
        }

        contentItem: BetterScrollListView {
            orientation: ListView.Vertical
            model: vtabbar.contentModel

            Rectangle {
                anchors.fill: parent
                border.color: "black"
                border.width: 1
                color: "transparent"
            }
        }
    }

    StackLayout {
        anchors.left: vtabbar.right
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.top: parent.top
        currentIndex: vtabbar.currentIndex

        Item {
            TabBar {
                id: htabbar
                width: parent.width
                TabButton {
                    width: implicitWidth
                    text: qsTr("Image Conversion")
                }
                TabButton {
                    width: implicitWidth
                    text: qsTr("Test")
                }

                contentItem: BetterScrollListView {
                    orientation: ListView.Horizontal
                    model: htabbar.contentModel
                }
            }

            StackLayout {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.top: htabbar.bottom
                currentIndex: htabbar.currentIndex

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

        Item {
            TabBar {
                id: htabbar2
                width: parent.width
                TabButton {
                    width: implicitWidth
                    text: qsTr("Video Conversion")
                }

                contentItem: BetterScrollListView {
                    orientation: ListView.Horizontal
                    model: htabbar2.contentModel
                }
            }

            StackLayout {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.top: htabbar2.bottom
                currentIndex: htabbar2.currentIndex

                Item {
                    Text {
                        anchors.centerIn: parent
                        text: "Coming Soon"
                    }
                }
            }
        }
    }
}


