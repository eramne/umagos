import QtQuick 2.14
import QtQuick.Controls 2.3
import QtQml.Models 2.2

ComboBox {
    editable: true
    property int _highlightedIndex: -1
    id: combobox
    property alias filteredDelegateModel: filteredDelegateModel
    property int separatorIndex: -1
    property bool searching: false

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
        var tmpAddedFormatList = []; //for checking for duplicates
        filteredListModel.clear();
        listview.contentItem.children.length = 0;
        combobox._highlightedIndex = -1;
        fileTypes.forEach( function (item) {
            let text = contentItem.text;
            if (contentItem.selectionEnd === contentItem.text.length) {
                text = text.substring(0, contentItem.selectionStart);
            }
            combobox.searching = text !== currentText;
            if (!combobox.searching || (item.startsWith(text) && !tmpAddedFormatList.includes(item))) {
                filteredListModel.append({
                    'text': item
                });
                tmpAddedFormatList.push(item);
            }
        });
    }

    Component.onCompleted: {
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
            background: Rectangle {
                Rectangle {
                    anchors.top: parent.top
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width * 2/3
                    height: 2
                    color: "#000000"
                    //if the files are being filtered, don't show the line.
                    //else, if the index where the line should be, show the line, else don't.
                    opacity: combobox.searching ? 0 : (index === separatorIndex ? 0.5 : 0)
                }

                color: highlighted ? "#0078D7" : "#FFFFFF"
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
            onAccepted();
        } else {
            contentItem.readOnly = false;
            popup.open();
        }
    }

    onAccepted: {
        if (find(editText) === -1) {
            editText = currentText;
        } else {
            currentIndex = find(editText);
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

    popup: Popup {
        width: combobox.width
        padding: 1

        background: Rectangle {
            anchors.fill: parent
            border.color: "black"
            border.width: 1
            color: "white"
        }

        contentItem: ScrollView {
            onContentHeightChanged: {
                parent.height = contentHeight;
            }

            BetterScrollListView {
                id: listview
                property int test: 0
                clip: true
                model: combobox.filteredDelegateModel
                currentIndex: combobox.highlightedIndex
                delegate: combobox.filteredDelegateModel.delegate
            }
        }
    }
}
