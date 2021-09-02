import QtQuick 2.14
import QtQuick.Window 2.14
import QtQuick.Controls 2.3
import QtQuick.Dialogs 1.0
import QtQml.Models 2.2
import umagos.components 1.0
import umagos.shellTask 1.0

Item {
    id: page
    visible: true
    property string tabId: Backend.makeUUID()
    property string outputPath: Backend.makeOutputPath(page.tabId)
    property var supportedFormats: Backend.getSupportedFormats().images

    function setFileControlsEnabled(value) {
        convertButton.text = value ? "Convert" : "Cancel";
        inputFileViewDropArea.setAcceptDrop(value);
        outputFormatBox._setEnabled(value);
        outFormatLabel.opacity = value ? 1 : 0.5;
        openFileButton._setEnabled(value);
    }

    ShellTask {
        id: task
        property var fileQueue: []
        property int stopcode: 0
        property int totalItems: -1
        property int currentItem: -1;
        property string targetExt: ".png";

        function startStopConversion(paths) {
            if (task.isRunning()) {
                task.abort();
            } else {
                task.startConversion(paths);
            }
        }

        function isRunning() {
            return fileQueue.length > 0;
        }

        function startConversion(paths) {
            task.targetExt = outputFormatBox.currentText;
            task.stopcode = 0;
            task.fileQueue = task.validate(paths);
            task.totalItems = task.fileQueue.length;
            task.currentItem = 0;
            log.log("Conversion starting.", Style.text.info.color);
            progressBar.setProgress(0,1);
            Backend.clearOutputDir(page.outputPath);
            outputFileView.updateList();
            page.setFileControlsEnabled(false);
            task.nextFile();
        }

        function validate(paths) {
            if (paths.length > 0) {
                var tempOldCount = paths.length;
                var filePathQueue = [...new Set(paths)];
                var duplicatesCount = tempOldCount - filePathQueue.length;
                if (duplicatesCount > 0) {
                    log.log(`Warning: There were ${duplicatesCount} duplicate files, these will be ignored during conversion.`, Style.text.warning.color);
                }

                var unsupportedFormats = [];
                var numFilesUnsupported = 0;
                var tempFilePathQueue = [];
                for (var i = 0; i < filePathQueue.length; i++) {
                    var path = filePathQueue[i];
                    var ext = Backend.getFileExtension(path);
                    if (!Backend.getSupportedFormats()["images"].includes(ext)) {
                        if (!unsupportedFormats.includes(ext)) {
                            unsupportedFormats.append(ext);
                        }
                        numFilesUnsupported += 1;
                    } else {
                        tempFilePathQueue.push(path);
                    }
                }
                paths = tempFilePathQueue;
                if (numFilesUnsupported > 0) {
                    log.log(`Warning: Unsupported formats: ${unsupportedFormats.join(", ")}. ${numFilesUnsupported} file(s) of those unsupported formats will be ignored during conversion.`, Style.text.warning.color);
                }
            } else {
                log.log("Error: Drag and drop your files to the left box, then click the Convert button to convert your files!", Style.text.error.color);
            }
            return paths;
        }

        function nextFile() {
            if (task.fileQueue.length > 0) {
                task.currentItem++;
                var path = fileQueue.shift();
                var inName = Backend.getFileNameWithoutExtension(path);
                var inExt = Backend.getFileExtension(path);

                var tmpOutFile = Backend.joinPaths(page.outputPath, `${inName}${task.targetExt}`);
                var outFile = Backend.getUsableName(tmpOutFile);
                if (tmpOutFile !== outFile) {
                    var newName = Backend.getFileName(outFile);
                    log.log(`Warning: File ${inName} already exists in output folder, most likely caused by two files with the same name being converted, file renamed to ${newName}. Full path of original: ${path}`, Style.text.warning.color);
                }

                if (Backend.fileExists(path)) {
                    log.log(`File ${task.currentItem}/${task.totalItems}, converting file ${inName}${inExt} from ${inExt} to ${task.targetExt}. Full path of original: ${path}`, Style.text.info.color);
                    var command = {
                        exe: Backend.getMagickPath(),
                        args: ["convert", path, outFile]
                    };
                    task.start([command]);
                } else {
                    log.log(`Error: File ${path} has been renamed, moved, or deleted, and could not be found.`, Style.text.info.color);
                }
            } else {
                task.allFinished();
            }
        }

        function abort() {
            task.stopcode = -1;
            task.kill();
            task.fileQueue.length = 0;
        }

        onFinished: {
            progressBar.setProgress(task.currentItem, task.totalItems);
            outputFileView.updateList();
            task.nextFile();
        }

        function allFinished() {
            switch (task.stopcode) {
                case 0:
                    log.log("Conversion finished.", Style.text.success.color);
                    break;
                case -1:
                    log.log("Conversion cancelled.", Style.text.error.color);
                    break;
            }
            page.setFileControlsEnabled(true);
            task.stopcode = 0;
            task.totalItems = -1;
            task.currentItem = -1;
        }
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
                    Backend.getClipboardUrls().forEach( function (url) {
                        inputFileView.paths.push(Backend.uriToPath(url));
                    });
                    inputFileView.updateList();
                }
            }

            Shortcut {
                id: inputRemoveShortcut
                enabled: inputFileView.activeFocus;
                sequences: [StandardKey.Delete, StandardKey.Backspace, "Backspace"]
                onActivated: {
                    var tmpPaths = [];
                    inputFileView.paths.forEach( function (path) {
                        if (!inputFileView.selectedIds.includes(path)) {
                            tmpPaths.push(path);
                        }
                    });
                    inputFileView.paths = tmpPaths;
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
                        inputPasteMenuItem.enabled = Backend.getClipboardUrls().length > 0;
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
                        inputFileView.paths.push(Backend.uriToPath(url));
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

            property var paths: []

            function updateList() {
                var shouldScrollToBottom = false;
                paths.forEach( function (item) {
                    if (inputFileView.indexOf(item) === -1) {
                        var file = Backend.pathToName(item);
                        inputFileView.model.append({"name":file,"id":item});
                        shouldScrollToBottom = true;
                    }
                });

                for (var i = 0; i < inputFileView.model.count; i++) {
                    var item = inputFileView.model.get(i);
                    if (!paths.includes(item.id)) {
                        inputFileView.model.remove(i);
                        i--;
                    }
                }

                var tmpCacheBuffer = inputFileView.cacheBuffer; //update the content width of the listview
                inputFileView.cacheBuffer = 999999999;
                inputFileView.contentWidth = inputFileView.contentItem.childrenRect.width;
                inputFileView.cacheBuffer = tmpCacheBuffer;

                inputFileView.selectionUpdated();

                if (shouldScrollToBottom) {
                    inputFileView.scrollToBottom();
                }
            }

            delegate: Item {
                id: delegate
                width: row.width
                height: row.height
                property bool selected: false

                Component.onCompleted: {
                    if (typeof inputFileView !== 'undefined') {
                        delegate.selected = inputFileView.getSelected(index);
                    }
                    inputFileView.selectionUpdated.connect(function () {
                        if (typeof inputFileView !== 'undefined') {
                            delegate.selected = inputFileView.getSelected(index);
                        }
                    });
                }

                Rectangle {
                    height: delegate.height
                    width: Math.max(inputFileView.width, inputFileView.contentWidth)
                    color: inputFileView.activeFocus ? "#aaaaff" : "#cccccc"
                    opacity: delegate.selected ? 1 : 0
                }

                Row {
                    id: row
                    padding: 5
                    width: text0.implicitWidth + padding*2
                    Text {
                        id: text0
                        text: name
                        anchors.verticalCenter: parent.verticalCenter
                        font.pixelSize: 12
                    }
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
                    Backend.setClipboardUrls(outputFileView.getSelectionUrls());
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
                        onTriggered: Backend.setClipboardUrls(outputFileView.getAllUrls());
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
            property var paths: []

            function updateList() {
                var highlightNewItem = outputFileView.model.count === 0 || outputFileView.getAllSelected();
                outputFileView.paths = Backend.getOutputFiles(page.outputPath);
                outputFileView.model.clear();

                paths.forEach( function (item) {
                    outputFileView.model.append({"name":item,"id":item});
                    if (highlightNewItem) {
                        outputFileView.selectedIds.push(item);
                    }
                });

                var tmpCacheBuffer = outputFileView.cacheBuffer; //update the content width of the listview
                outputFileView.cacheBuffer = 999999999;
                outputFileView.contentWidth = outputFileView.contentItem.childrenRect.width;
                outputFileView.cacheBuffer = tmpCacheBuffer;

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
                for (var i = 0; i < outputFileView.paths.length; i++) {
                    if (outputFileView.selectedIds.includes(outputFileView.paths[i])) {
                        urls += Backend.pathToURI(page.outputPath) + "/" + outputFileView.paths[i] + "\r\n";
                    }
                }
                return urls;
            }

            function getAllUrls() {
                var urls = "";
                for (var i = 0; i < outputFileView.paths.length; i++) {
                    urls += Backend.pathToURI(page.outputPath) + "/" + outputFileView.paths[i] + "\r\n";
                }
                return urls;
            }

            delegate: Item {
                id: delegate1
                width: row1.width
                height: row1.height
                property bool selected: false

                Component.onCompleted: {
                    if (typeof outputFileView !== 'undefined') {
                        delegate1.selected = outputFileView.getSelected(index);
                    }
                    outputFileView.selectionUpdated.connect(function () {
                        if (typeof outputFileView !== 'undefined') {
                            delegate1.selected = outputFileView.getSelected(index);
                        }
                    });
                }

                Rectangle {
                    height: delegate1.height
                    width: Math.max(outputFileView.width, outputFileView.contentWidth)
                    color: outputFileView.activeFocus ? "#aaaaff" : "#cccccc"
                    opacity: delegate1.selected ? 1 : 0
                }

                Row {
                    id: row1
                    padding: 5
                    width: text1.implicitWidth + padding*2
                    Text {
                        id: text1
                        text: name
                        anchors.verticalCenter: parent.verticalCenter
                        font.pixelSize: 12
                    }
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
            task.startStopConversion(inputFileView.paths);
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
            updateList(page.supportedFormats);
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

                function log(message, color) {
                    text = text + `<p style='color: ${color}'>${message}</p>\n`;
                    logFlickable.scrollToBottom();
                }

                Component.onCompleted: {
                    log.log("Info, errors, and warnings will appear here.", Style.text.info.color);
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

        function setProgress(progress, total) {
            value = progress;
            to = total;
        }
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
                inputFileView.paths.push(Backend.uriToPath(url));
            });
        }
        Component.onCompleted: {
            var formats = Backend.getSupportedFormats();
            nameFilters.unshift("Image files (*" + formats.images.join(" *") + ")");
        }
    }
}

/*##^##
Designer {
    D{i:0;autoSize:true;height:480;width:640}
}
##^##*/
