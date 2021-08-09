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

    ScrollView {
        x: 90
        y: 112
        width: 188
        height: 184
        clip: true

        function scroll(val, horiz = false) {
            var scrollbar = horiz ? ScrollBar.horizontal : ScrollBar.vertical;
            scrollbar.stepSize = val;
            scrollbar.decrease();
            scrollbar.stepSize = 0;
            inputFileView.returnToBounds();
            inputFileView.contentX -= inputFileView.horizontalOvershoot;
            console.log(inputFileView.horizontalOvershoot);
        }

        ListView {
            id: inputFileView
            objectName: "inputFileView"
            visible: true
            flickDeceleration: 3000
            flickableDirection: Flickable.HorizontalAndVerticalFlick
            implicitWidth: contentItem.childrenRect.width
            anchors.fill: parent
            interactive: false
            //boundsBehavior: Flickable.DragOverBounds
            //maximumFlickVelocity: 3000
            //flickDeceleration: 10000
            spacing: 0

            function updateList(paths) {
                inputFileModel.clear();
                paths.forEach( function (item) {
                    inputFileModel.append({
                        'name': item
                    });
                });
                var max = 0;
                for(var i = 0; i < inputFileView.count; i++) {
                    inputFileView.currentIndex = i
                    var itemWidth = inputFileView.currentItem.x + inputFileView.currentItem.childrenRect.width
                    max = Math.max(max, itemWidth)
                }
                inputFileView.contentWidth = max + 5; //+5 to add some extra padding
                inputFileView.parent.scroll(1);
                inputFileView.parent.scroll(1, true);
            }

            WheelHandler {
                //acceptedDevices: PointerDevice.TouchPad
                onWheel: {
                    var delta = event.hasPixelDelta ? event.pixelDelta : event.angleDelta;
                    //console.log(delta);
                    if (event.modifiers & Qt.ShiftModifier) {
                        inputFileView.parent.scroll(delta.y/3000, true)
                    } else {
                        inputFileView.parent.scroll(delta.y/3000)
                    }
                }
            }

            model: ListModel {
                id: inputFileModel
            }
            delegate: Item {
                x: 5
                height: 20
                Row {
                    Text {
                        text: name
                        anchors.verticalCenter: parent.verticalCenter
                        font.pixelSize: 12
                    }
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
    }

    ListView {
        id: outputFileView
        // @disable-check M16
        objectName: "outputFileView"
        visible: true
        clip: true
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
                    font.pixelSize: 12
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
        id: outFormatLabel
        // @disable-check M16
        objectName: "outFormatLabel"
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
