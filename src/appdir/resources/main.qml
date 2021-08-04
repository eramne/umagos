import QtQuick 2.14
import QtQuick.Window 2.14
import QtQuick.Controls 2.3

Item {
    id: window
    width: 640
    height: 480
    visible: true

    Rectangle {
        anchors.fill: parent
        color: "white"
    }

    ListView {
        id: inputFileView
        // @disable-check M16
        objectName: "inputFileView"
        visible: true
        clip: true
        boundsBehavior: Flickable.DragOverBounds
        flickableDirection: Flickable.VerticalFlick
        spacing: 0
        x: 90
        y: 112
        width: 188
        height: 184

        function updateList(paths) {
            inputFileModel.clear();
            paths.forEach( function (item) {
                inputFileModel.append({
                    'name': item
                });
            });
        }

        model: ListModel {
            id: inputFileModel
        }
        delegate: Item {
            x: 5
            width: 80
            height: 20
            Row {
                Text {
                    text: name
                    anchors.verticalCenter: parent.verticalCenter
                    font.pointSize: 10
                    font.family: "Arial"
                }
                spacing: 10
            }
        }

        Rectangle {
            anchors.fill: parent
            border.color: "black"
            border.width: 1
            color: "transparent"
        }

        DropArea {
            anchors.fill: parent
            id: inputFileViewDropArea
            // @disable-check M16
            objectName: "inputFileViewDropArea"
            onDropped: function (drop) {
                drop.urls.forEach( function (url) {
                    backend.addToPaths(url)
                });
            }

            function setAcceptDrop(value) {
                inputFileView.opacity = value ? 1 : 0.5;
                enabled = value;
            }
        }
    }

    ListView {
        id: outputFileView
        // @disable-check M16
        objectName: "outputFileView"
        visible: true
        clip: true
        boundsBehavior: Flickable.DragOverBounds
        flickableDirection: Flickable.VerticalFlick
        spacing: 0
        x: 390
        y: 112
        width: 188
        height: 184

        function updateList(paths) {
            outputFileModel.clear();
            paths.forEach( function (item) {
                outputFileModel.append({
                    'name': item
                });
            });
        }

        model: ListModel {
            id: outputFileModel
        }
        delegate: Item {
            x: 5
            width: 80
            height: 20
            Row {
                Text {
                    text: name
                    anchors.verticalCenter: parent.verticalCenter
                    font.pointSize: 10
                    font.family: "Arial"
                }
                spacing: 10
            }
        }

        Rectangle {
            anchors.fill: parent
            border.color: "black"
            border.width: 1
            color: "transparent"
        }

        Item {
            anchors.fill: parent
            Drag.active: dragArea.drag.active
            Drag.dragType: Drag.Automatic
            Drag.supportedActions: Qt.CopyAction
            Drag.mimeData: {
                "text/plain": "Copied text"
            }

            MouseArea {
                id: dragArea
                //drag.target: parent
                anchors.fill: parent
                drag.target: parent
                onPressed: {
                    parent.Drag.imageSource = "data:image/gif;base64,R0lGODlhAQABAAD/ACwAAAAAAQABAAACADs%3D";
                    signalHandler.onOutputFileUpdate()
                    var urls = "";
                    for (var i = 0; i < outputFileModel.count; i++) {
                        urls += backend.getOutputPathUrl() + "/" + outputFileModel.get(i).name + "\r\n"
                    }
                    parent.Drag.mimeData = {"text/uri-list": urls};
                }
            }
        }
    }

    Button {
        id: btn_clearInputSelection
        // @disable-check M16
        objectName: "btn_clearInputSelection"
        x: 90
        y: 302
        width: 100
        height: 25
        text: qsTr("Clear selection")
        onClicked: {
            backend.clearInputSelection()
        }
        function _setEnabled(value) {
            opacity = value ? 1 : 0.5;
            enabled = value;
        }
    }

    Button {
        id: btn_convert
        // @disable-check M16
        objectName: "btn_convert"
        x: 285
        y: 192
        width: 100
        height: 25
        text: qsTr("Convert")
        onClicked: {
            backend.callConversion()
        }
    }

    Text {
        id: text1
        x: 296
        y: 44
        width: 134
        height: 22
        text: qsTr("Convert to file type:")
        font.pixelSize: 12
    }

    ComboBox {
        id: outputFormatBox
        // @disable-check M16
        objectName: "outputFormatBox"
        x: 436
        y: 35

        function updateList(fileTypes) {
            inputFileModel.clear();
            fileTypes.forEach( function (item) {
                imageFormatComboBoxModel.append({
                    'text': item
                });
            });
        }

        // @disable-check M16
        Component.onCompleted: {
            updateList(backend.getSupportedImageFormats());
            currentIndex = 0;
        }

        model: ListModel {
            id: imageFormatComboBoxModel
        }

        function _setEnabled(value) {
            opacity = value ? 1 : 0.5;
            enabled = value;
        }
    }

    ScrollView {
        id: logScrollView
        // @disable-check M16
        objectName: "logScrollView"
        x: 90
        y: 333
        clip: true
        width: 488
        height: 110

        function scrollToBottom() {
            ScrollBar.vertical.position = 1.0 - ScrollBar.vertical.size
            ScrollBar.horizontal.position = 0
        }

        Text {
            id: log
            // @disable-check M16
            objectName: "log"
            anchors.fill: parent
            text: ""
            font.pixelSize: 12
            lineHeight: 0.25
            bottomPadding: 20
            textFormat: Text.RichText

            Rectangle {
                anchors.fill: parent
                visible: false
            }
        }
    }

    ProgressBar {
        id: progressBar
        // @disable-check M16
        objectName: "progressBar"
        x: 90
        y: 450
        width: 488
        height: 22
        to: 1
        value: 0
    }
}
