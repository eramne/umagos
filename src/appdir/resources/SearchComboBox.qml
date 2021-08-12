import QtQuick 2.14
import QtQuick.Controls 2.3
import QtQml.Models 2.2

ComboBox {
    editable: true
    property int _highlightedIndex: -1

    function updateList(fileTypes) {
        imageFormatComboBoxModel.clear();
        fileTypes.forEach( function (item) {
            imageFormatComboBoxModel.append({
                'text': item
            });
        });
        updateFilteredList(fileTypes);
    }

    function updateFilteredList(fileTypes) {
        filteredImageFormatListModel.clear();
        fileTypes.forEach( function (item) {
            let text = contentItem.text;
            if (contentItem.selectionEnd === contentItem.text.length) {
                text = text.substring(0, contentItem.selectionStart);
            }
            if (text === currentText || item.startsWith(text)) {
                filteredImageFormatListModel.append({
                    'text': item
                });
            }
        });
    }

    Component.onCompleted: {
        popup.contentItem.model = filteredImageFormatDelegateModel;
        currentIndex = 0;
        popup.y = height - 1;
        popup.closed.connect(onAccepted);
        contentItem.onCursorPositionChanged.connect(function () {
            updateFilteredList(backend.getSupportedFormats().images);
        });
        contentItem.onSelectionEndChanged.connect(function () {
            updateFilteredList(backend.getSupportedFormats().images);
        });
        contentItem.onSelectionStartChanged.connect(function () {
            updateFilteredList(backend.getSupportedFormats().images);
        });
    }

    model: ListModel {
        id: imageFormatComboBoxModel
    }

    DelegateModel {
        id: filteredImageFormatDelegateModel
        model: ListModel {
            id: filteredImageFormatListModel
        }
        delegate: ItemDelegate {
            width: outputFormatBox.width
            contentItem: Text {
                text: modelData
            }
            onHoveredChanged: {
                outputFormatBox._highlightedIndex = hovered ? index : -1;
            }
            onPressed: {
                outputFormatBox.currentIndex = outputFormatBox.find(modelData);
                outputFormatBox.focus = false;
            }
            highlighted: outputFormatBox._highlightedIndex === index
        }
    }

    onActiveFocusChanged: {
        if (!activeFocus) {
            editText = currentText;
        } else {
            contentItem.readOnly = false;
            popup.open();
        }
    }

    onAccepted: {
        if (find(editText) === -1) {
            editText = currentText;
        }
        focus = false;
    }

    onEditTextChanged: {
        editText = editText.trim();
        if (!editText.startsWith(".")) {
            editText = "." + editText;
        }
    }

    MouseArea {
        anchors.fill: parent
        onReleased: {
            parent.focus = true;
        }
    }
}
