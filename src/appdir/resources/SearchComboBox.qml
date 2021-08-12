import QtQuick 2.14
import QtQuick.Controls 2.3
import QtQml.Models 2.2

ComboBox {
    editable: true
    property int _highlightedIndex: -1
    id: combobox

    function updateList(fileTypes) {
        model.clear();
        fileTypes.forEach( function (item) {
            model.append({
                'text': item
            });
        });
        updateFilteredList(fileTypes);
    }

    function updateFilteredList(fileTypes) {
        filteredListModel.clear();
        fileTypes.forEach( function (item) {
            let text = contentItem.text;
            if (contentItem.selectionEnd === contentItem.text.length) {
                text = text.substring(0, contentItem.selectionStart);
            }
            if (text === currentText || item.startsWith(text)) {
                filteredListModel.append({
                    'text': item
                });
            }
        });
    }

    Component.onCompleted: {
        popup.contentItem.model = filteredDelegateModel;
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
        id: model
    }

    DelegateModel {
        id: filteredDelegateModel
        model: ListModel {
            id: filteredListModel
        }
        delegate: ItemDelegate {
            width: combobox.width
            contentItem: Text {
                text: modelData
            }
            onHoveredChanged: {
                combobox._highlightedIndex = hovered ? index : -1;
            }
            onPressed: {
                combobox.currentIndex = combobox.find(modelData);
                combobox.focus = false;
            }
            highlighted: combobox._highlightedIndex === index
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
