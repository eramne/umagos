import QtQuick 2.14
import QtQuick.Window 2.14
import QtQuick.Controls 2.3
import QtQuick.Dialogs 1.0
import QtQml.Models 2.2

Item {
    id: window
    width: 640
    height: 480
    visible: true

    function setFileControlsEnabled(value) {
        convertButton.text = value ? "Convert" : "Cancel";
        inputFileViewDropArea.setAcceptDrop(value);
        clearInputSelectionButton._setEnabled(value);
        outputFormatBox._setEnabled(value);
        outFormatLabel.opacity = value ? 1 : 0.5;
        openFileButton._setEnabled(value);
        openFromClipboardButton._setEnabled(value);
    }

    Rectangle {
        anchors.fill: parent
        color: "white"
    }

    ScrollView {
        id: inputFileScrollView
        x: 90
        y: 112
        width: 188
        height: 184
        clip: true

        background: Rectangle {
            anchors.fill: parent
            border.color: "black"
            border.width: 1
            color: "transparent"

            DropArea {
                anchors.fill: parent
                id: inputFileViewDropArea
                objectName: "inputFileViewDropArea"
                onDropped: function (drop) {
                    drop.urls.forEach( function (url) {
                        backend.addToPaths(url);
                    });
                }

                function setAcceptDrop(value) {
                    inputFileScrollView.opacity = value ? 1 : 0.5;
                    enabled = value;
                }
            }
        }

        BetterScrollFlickable {
            id: inputFileViewFlickable
            flickableDirection: Flickable.HorizontalAndVerticalFlick
            anchors.fill: parent
            contentWidth: inputFileView.implicitWidth
            contentHeight: inputFileView.implicitHeight

            Text {
                id: inputFileView
                objectName: "inputFileView"
                text: ""
                anchors.fill: parent
                font.pixelSize: 12
                padding: 5

                function updateList(paths) {
                    inputFileView.text = "";
                    paths.forEach( function (item) {
                        inputFileView.text += item + "\r\n";
                    });
                    inputFileView.text = inputFileView.text.trim();
                    inputFileViewFlickable.scrollToBottom();
                }
            }
        }
    }

    ScrollView {
        id: outputFileScrollView
        x: 390
        y: 112
        width: 188
        height: 184
        clip: true
        property var outputFiles: []

        background: Rectangle {
            anchors.fill: parent
            border.color: "black"
            border.width: 1
            color: "transparent"

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
                    for (var i = 0; i < outputFileScrollView.outputFiles.length; i++) {
                        urls += backend.getOutputPathUrl() + "/" + outputFileScrollView.outputFiles[i] + "\r\n"
                    }
                    parent.Drag.mimeData = {"text/uri-list": urls};
                }
            }
        }

        BetterScrollFlickable {
            id: outputFileViewFlickable
            flickableDirection: Flickable.HorizontalAndVerticalFlick
            contentWidth: outputFileView.implicitWidth
            contentHeight: outputFileView.implicitHeight
            anchors.fill: parent

            Text {
                id: outputFileView
                objectName: "outputFileView"
                text: ""
                anchors.fill: parent
                font.pixelSize: 12
                padding: 5

                function updateList(paths) {
                    outputFileScrollView.outputFiles = paths;
                    outputFileView.text = "";
                    paths.forEach( function (item) {
                        outputFileView.text += item + "\r\n"
                    });
                    outputFileView.text = outputFileView.text.trim();
                    outputFileViewFlickable.scrollToBottom();
                }
            }
        }
    }

    Button {
        id: clearInputSelectionButton
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
        id: openFileButton
        x: 196
        y: 302
        width: 79
        height: 25
        text: qsTr("Open Files")
        onClicked: {
            openFileDialog.visible = true;
        }
        function _setEnabled(value) {
            opacity = value ? 1 : 0.5;
            enabled = value;
        }
    }

    Button {
        id: openFromClipboardButton
        x: 281
        y: 302
        width: 79
        height: 25
        text: qsTr("Paste files")
        onClicked: {
            backend.getClipboardUrls().forEach( function (url) {
                backend.addToPaths(url);
            });
        }
        function _setEnabled(value) {
            opacity = value ? 1 : 0.5;
            enabled = value;
        }
    }

    Button {
        id: convertButton
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
        objectName: "outFormatLabel"
        x: 296
        y: 44
        width: 134
        height: 22
        text: qsTr("Convert to file type:")
        font.pixelSize: 12
    }

    SearchComboBox {
        id: outputFormatBox
        objectName: "outputFormatBox"
        x: 436
        y: 35

        Component.onCompleted: {
            updateList(backend.getSupportedFormats().images);
        }
    }

    ScrollView {
        id: logScrollView
        objectName: "logScrollView"
        x: 90
        y: 333
        clip: true
        width: 488
        height: 110

        background: Rectangle {
            anchors.fill: parent
            border.color: "black"
            border.width: 1
            color: "transparent"
        }

        BetterScrollFlickable {
            id: logFlickable
            objectName: "logFlickable"
            flickableDirection: Flickable.HorizontalAndVerticalFlick
            anchors.fill: parent
            contentWidth: log.implicitWidth
            contentHeight: log.implicitHeight

            Text {
                id: log
                objectName: "log"
                anchors.fill: parent
                text: ""
                font.pixelSize: 12
                lineHeight: 0.25
                padding: 5
                bottomPadding: 20
                textFormat: Text.RichText

                Rectangle {
                    anchors.fill: parent
                    visible: false
                }
            }
        }
    }

    ProgressBar {
        id: progressBar
        objectName: "progressBar"
        x: 90
        y: 450
        width: 488
        height: 22
        to: 1
        value: 0
    }

    FileDialog {
        id: openFileDialog
        objectName: "openFileDialog"
        title: "Open files"
        folder: shortcuts.home
        selectExisting: true
        selectMultiple: true
        nameFilters: ["All files (*)"]
        onAccepted: {
            openFileDialog.fileUrls.forEach( function (url) {
                backend.addToPaths(url);
            });
        }
        Component.onCompleted: {
            var formats = backend.getSupportedFormats();
            nameFilters.unshift("Image files (*" + formats.images.join(" *") + ")");
        }
    }
}
