import QtQuick 2.14
import QtQuick.Window 2.14
import QtQuick.Controls 2.3
import QtQuick.Dialogs 1.0
import QtQml.Models 2.2
import umagos.components 1.0

Item {
    id: page
    visible: true

    function setFileControlsEnabled(value) {
        convertButton.text = value ? "Convert" : "Cancel";
        inputFileViewDropArea.setAcceptDrop(value);
        outputFormatBox._setEnabled(value);
        outFormatLabel.opacity = value ? 1 : 0.5;
        openFileButton._setEnabled(value);
    }

    ScrollView {
        id: inputFileScrollView
        x: 90
        y: 112
        width: 188
        height: 184
        clip: true
        padding: 5

        background: Rectangle {
            anchors.fill: parent
            border.color: inputFileView.activeFocus ? "blue" : "black"
            border.width: 1
            color: "transparent"

            MouseArea {
                anchors.fill: parent
                propagateComposedEvents: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onPressed: {
                    inputFileView.forceActiveFocus();
                    mouse.accepted = false;
                }
            }

            Shortcut {
                id: inputPasteShortcut
                enabled: inputFileView.activeFocus;
                sequence: StandardKey.Paste
                onActivated: {
                    backend.getClipboardUrls().forEach( function (url) {
                        backend.addToPaths(url);
                    });
                    inputFileView.updateList(backend.getPaths());
                }
            }

            Shortcut {
                id: inputRemoveShortcut
                enabled: inputFileView.activeFocus;
                sequences: [StandardKey.Delete, StandardKey.Backspace, "Backspace"]
                onActivated: {
                    backend.removeFromInputSelection(inputFileView.selectedIds);
                    inputFileView.updateList();
                }
            }

            Shortcut {
                id: inputSelectAllShortcut
                enabled: inputFileView.activeFocus;
                sequence: StandardKey.SelectAll
                onActivated: {
                    inputFileView.selectedIds.length = 0;
                    for (var i = 0; i < inputFileView.model.count; i++) {
                        inputFileView.selectedIds.push(inputFileView.idOf(i));
                    }
                    inputFileView.selectionUpdated();
                }
            }

            MouseArea {
                anchors.fill: parent
                propagateComposedEvents: true
                acceptedButtons: Qt.RightButton
                onClicked: {
                    inputContextMenu.popup();
                    mouse.accepted = false;
                }

                Menu {
                    id: inputContextMenu
                    width: 250
                    MenuItem {
                        id: inputPasteMenuItem
                        text: `Paste files (${inputPasteShortcut.nativeText})`
                        onTriggered: inputPasteShortcut.activated()
                        opacity: enabled ? 1 : 0.5
                    }
                    MenuItem {
                        text: `Remove selected files (Backspace)`
                        onTriggered: inputRemoveShortcut.activated()
                        opacity: enabled ? 1 : 0.5
                        enabled: inputFileView.selectedIds.length > 0
                    }
                    MenuItem {
                        text: `Select All (${inputSelectAllShortcut.nativeText})`
                        onTriggered: inputSelectAllShortcut.activated()
                        opacity: enabled ? 1 : 0.5
                        enabled: inputFileView.model.count > 0
                    }

                    onOpened: {
                        inputPasteMenuItem.enabled = backend.getClipboardUrls().length > 0;
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                text: qsTr("Drag files to convert here")
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.WordWrap
                opacity: inputFileView.model.count > 0 ? 0 : 1
                width: parent.width * 2/3
            }

            DropArea {
                anchors.fill: parent
                id: inputFileViewDropArea
                objectName: "inputFileViewDropArea"
                onDropped: function (drop) {
                    drop.urls.forEach( function (url) {
                        backend.addToPaths(url);
                    });
                    inputFileView.updateList();
                    inputFileView.forceActiveFocus();
                }

                function setAcceptDrop(value) {
                    inputFileScrollView.opacity = value ? 1 : 0.5;
                    inputFileScrollView.background.enabled = value;
                    inputFileView.contentItem.enabled = value;
                }
            }
        }

        contentItem: MultiselectListView {
            id: inputFileView
            objectName: "inputFileView"
            anchors.fill: parent
            z: -1

            function updateList() {
                var paths = backend.getPaths();
                paths.forEach( function (item) {
                    if (inputFileView.indexOf(item) === -1) {
                        var file = backend.pathToName(item);
                        inputFileView.model.append({"name":file,"id":item});
                    }
                });

                for (var i = 0; i < inputFileView.model.count; i++) {
                    var item = inputFileView.model.get(i);
                    if (!paths.includes(item.id)) {
                        inputFileView.model.remove(i);
                        i--;
                    }
                }

                contentWidth = contentItem.childrenRect.width;

                var tmpCacheBuffer = inputFileView.cacheBuffer; //update the content width of the listview
                inputFileView.cacheBuffer = 999999999;
                inputFileView.contentWidth = inputFileView.contentItem.childrenRect.width;
                inputFileView.cacheBuffer = tmpCacheBuffer;

                inputFileView.selectionUpdated();
            }

            rowDelegate: Row {
                padding: 5
                width: text2.implicitWidth + padding*2
                Text {
                    id: text2
                    text: itemData.name
                    anchors.verticalCenter: parent.verticalCenter
                    font.pixelSize: 12
                }
            }
        }
    }

    ScrollView {
        x: 390
        y: 112
        width: 188
        height: 184
        clip: true
        padding: 5

        background: Rectangle {
            anchors.fill: parent
            border.color: outputFileView.activeFocus ? "blue" : "black"
            border.width: 1
            color: "transparent"
            z: 1

            Shortcut {
                id: outputSelectAllShortcut
                enabled: outputFileView.activeFocus;
                sequence: StandardKey.SelectAll
                onActivated: {
                    outputFileView.selectedIds.length = 0;
                    for (var i = 0; i < outputFileView.model.count; i++) {
                        outputFileView.selectedIds.push(outputFileView.idOf(i));
                    }
                    outputFileView.selectionUpdated();
                }
            }

            Shortcut {
                id: outputCopyShortcut
                enabled: outputFileView.activeFocus;
                sequence: StandardKey.Copy
                onActivated: {
                    backend.setClipboardUrls(outputFileView.getSelectionUrls());
                }
            }

            MouseArea {
                anchors.fill: parent
                propagateComposedEvents: true
                acceptedButtons: Qt.RightButton
                onClicked: {
                    outputContextMenu.popup();
                    mouse.accepted = false;
                }

                Menu {
                    id: outputContextMenu
                    width: 250
                    MenuItem {
                        text: `Copy selected files (${outputCopyShortcut.nativeText})`
                        onTriggered: outputCopyShortcut.activated()
                        opacity: enabled ? 1 : 0.5
                        enabled: outputFileView.selectedIds.length > 0
                    }
                    MenuItem {
                        text: `Copy all files`
                        onTriggered: backend.setClipboardUrls(outputFileView.getAllUrls());
                        opacity: enabled ? 1 : 0.5
                        enabled: outputFileView.model.count > 0
                    }
                    MenuItem {
                        text: `Select All (${outputSelectAllShortcut.nativeText})`
                        onTriggered: outputSelectAllShortcut.activated()
                        opacity: enabled ? 1 : 0.5
                        enabled: outputFileView.model.count > 0
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                text: qsTr("Drag converted files out from here")
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.WordWrap
                opacity: outputFileView.model.count > 0 ? 0 : 1
                width: parent.width * 2/3
            }

            Drag.active: dragArea.drag.active
            Drag.dragType: Drag.Automatic
            Drag.supportedActions: Qt.CopyAction
            Drag.mimeData: {
                "text/plain": ""
            }

            MouseArea {
                id: dragArea
                anchors.fill: parent
                drag.target: parent
                propagateComposedEvents: true
                onPressed: dragImage.grabToImage(function(result) {
                    parent.Drag.imageSource = "data:image/gif;base64,R0lGODlhAQABAAD/ACwAAAAAAQABAAACADs%3D";
                    var urls = outputFileView.getSelectionUrls();
                    parent.Drag.mimeData = {"text/uri-list": urls};

                    if (outputFileView.selectedIds.length > 0) {
                        parent.Drag.imageSource = result.url;
                    } else {
                        parent.Drag.cancel();
                    }

                    outputFileView.forceActiveFocus();
                })
                Item {
                    id: dragImage
                    visible: false
                    property int displacement: 20
                    width: dragImageRect.width + displacement
                    height: dragImageRect.height

                    Rectangle {
                        id: dragImageRect
                        x: dragImage.displacement
                        property int padding: 5
                        width: dragImageText.implicitWidth + padding*2
                        height: dragImageText.implicitHeight + padding*2
                        color: "#cccccc"
                        Text {
                            id: dragImageText
                            x: parent.padding
                            y: parent.padding
                            text: outputFileView.selectedIds.length + " file(s)"

                            Component.onCompleted: {
                                outputFileView.selectionUpdated.connect(function () {
                                    text = outputFileView.selectedIds.length + " file(s)";
                                });
                            }
                        }
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                propagateComposedEvents: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onPressed: {
                    outputFileView.forceActiveFocus();
                    mouse.accepted = false;
                }
            }
        }

        contentItem: MultiselectListView {
            id: outputFileView
            objectName: "outputFileView"
            anchors.fill: parent
            property var outputFiles: []

            function updateList(paths) {
                var highlightNewItem = outputFileView.model.count === 0 || outputFileView.getAllSelected();
                outputFileView.outputFiles = paths;
                outputFileView.model.clear();

                paths.forEach( function (item) {
                    outputFileView.model.append({"name":item,"id":item});
                    if (highlightNewItem) {
                        outputFileView.selectedIds.push(item);
                    }
                });

                var max = 0;
                for(var i = 0; i < outputFileView.count; i++) {
                    outputFileView.currentIndex = i;
                    var itemWidth = outputFileView.currentItem.contentItem.width;
                    max = Math.max(max, itemWidth);
                }
                outputFileView.contentWidth = max;

                outputFileView.scrollToBottom();
                outputFileView.selectionUpdated();
            }

            function getAllSelected() {
                for (var i = 0; i < outputFileView.model.count; i++) {
                    if (!outputFileView.getSelected(i)) {
                        return false;
                    }
                }
                return true;
            }

            function getSelectionUrls() {
                var urls = "";
                for (var i = 0; i < outputFileView.outputFiles.length; i++) {
                    if (outputFileView.selectedIds.includes(outputFileView.outputFiles[i])) {
                        urls += backend.getOutputPathUrl() + "/" + outputFileView.outputFiles[i] + "\r\n";
                    }
                }
                return urls;
            }

            function getAllUrls() {
                var urls = "";
                for (var i = 0; i < outputFileView.outputFiles.length; i++) {
                    urls += backend.getOutputPathUrl() + "/" + outputFileView.outputFiles[i] + "\r\n";
                }
                return urls;
            }

            rowDelegate: Row {
                padding: 5
                width: text1.implicitWidth + padding*2
                Text {
                    id: text1
                    text: itemData.name
                    anchors.verticalCenter: parent.verticalCenter
                    font.pixelSize: 12
                }
            }
        }
    }

    Button {
        id: openFileButton
        x: 90
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
        separatorIndex: 12

        Component.onCompleted: {
            updateList(backend.getSupportedFormats().images);
        }

        function _setEnabled(value) {
            opacity = value ? 1 : 0.5;
            enabled = value;
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
