import QtQuick 2.14
import QtQuick.Controls 2.3

BetterScrollListView {
    id: listview
    property Component rowDelegate: Component { Item {} }
    property Component highlightItem: Component {
        Rectangle {
            color: "#aaaaff"
        }
    }
    property var selectedIndices: []
    property int lastSelectedIndex: -1

    function updateSelection() {
        for (var i = 0; i < listmodel.count; i++) {
            listmodel.setProperty(i, "selected", listview.selectedIndices.includes(i));
        }
    }

    model: ListModel {
        id: listmodel
    }
    delegate: Item {
        id: rowItem
        height: loader.item.height
        property bool selected: listview.selectedIndices.includes(index)
        property alias contentItem: loader.item

        Item {
            height: rowItem.height
            width: Math.max(listview.width, listview.contentWidth)
            opacity: selected ? 1 : 0

            Loader {
                sourceComponent: listview.highlightItem
                id: highlightLoader
                anchors.fill: parent
                property var itemData: ({});
                property int index: model.index

                Component.onCompleted: {
                    itemData = Object.assign({}, listmodel.get(index));
                }
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: {
                    if (mouse.button == Qt.LeftButton) {
                        if (!(mouse.modifiers & Qt.ControlModifier) && !(mouse.modifiers & Qt.ShiftModifier)) {
                            listview.selectedIndices = [index];
                            listview.lastSelectedIndex = index;
                        }

                        if (mouse.modifiers & Qt.ControlModifier) {
                            if (!rowItem.selected) {
                                listview.selectedIndices.push(index);
                            } else {
                                const indexToRemove = listview.selectedIndices.indexOf(index);
                                if (indexToRemove > -1) {
                                    listview.selectedIndices.splice(indexToRemove, 1);
                                }
                            }
                        }
                        if (mouse.modifiers & Qt.ShiftModifier) {
                            if (!(mouse.modifiers & Qt.ControlModifier)) {
                                listview.selectedIndices = [];
                            }
                            var min = Math.min(listview.lastSelectedIndex, index);
                            var max = Math.max(listview.lastSelectedIndex, index);
                            for (var i = min; i <= max; i++) {
                                listview.selectedIndices.push(i);
                            }
                        } else {
                            listview.lastSelectedIndex = index;
                        }
                    } else if (mouse.button == Qt.RightButton) {
                        if ((mouse.modifiers != Qt.ControlModifier) && !selected) {
                            listview.selectedIndices = [index];
                        }
                        listview.lastSelectedIndex = index;
                    }
                    listview.updateSelection();
                    listview.selectedIndices = [...new Set(listview.selectedIndices)];
                }
            }
        }

        Loader {
            sourceComponent: listview.rowDelegate
            id: loader
            property var itemData: ({});
            property int index: model.index

            Component.onCompleted: {
                itemData = Object.assign({}, listmodel.get(index));
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        z: -1
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: {
            listview.selectedIndices = [];
            listview.updateSelection();
        }
    }
}
