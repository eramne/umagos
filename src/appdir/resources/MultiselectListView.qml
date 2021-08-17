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
    property var selectedIds: []
    property int lastSelectedIndex: -1

    function updateSelection() {
        for (var i = 0; i < listmodel.count; i++) {
            var identifier = listmodel.get(i).identifier;
            listmodel.setProperty(i, "selected", listview.selectedIds.includes(identifier));
        }
    }

    function indexOf(_id) {
        for (var i = 0; i < listmodel.count; i++) {
            if (listview.idOf(i) === _id) {
                return i;
            }
        }
        return -1;
    }

    function idOf(_index) {
        listview.currentIndex = _index;
        return listview.currentItem.identifier;
    }

    function itemAt(_index) {
        listview.currentIndex = _index;
        return listview.currentItem;
    }

    model: ListModel {
        id: listmodel
    }
    delegate: Item {
        id: rowItem
        property var identifier: typeof model.id === 'undefined' ? index : model.id
        height: loader.item.height
        property bool selected: listview.selectedIds.includes(identifier)
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
                propagateComposedEvents: true
                onClicked: {
                    if (mouse.button == Qt.LeftButton) {
                        if (!(mouse.modifiers & Qt.ControlModifier) && !(mouse.modifiers & Qt.ShiftModifier)) {
                            listview.selectedIds = [identifier];
                            listview.lastSelectedIndex = index;
                        }

                        if (mouse.modifiers & Qt.ControlModifier) {
                            if (!rowItem.selected) {
                                listview.selectedIds.push(identifier);
                            } else {
                                const indexToRemove = listview.selectedIds.indexOf(identifier);
                                if (indexToRemove > -1) {
                                    listview.selectedIds.splice(indexToRemove, 1);
                                }
                            }
                        }
                        if (mouse.modifiers & Qt.ShiftModifier) {
                            if (!(mouse.modifiers & Qt.ControlModifier)) {
                                listview.selectedIds = [];
                            }
                            var min = Math.min(listview.lastSelectedIndex, index);
                            var max = Math.max(listview.lastSelectedIndex, index);
                            for (var i = min; i <= max; i++) {
                                listview.selectedIds.push(listview.idOf(i));
                            }
                        } else {
                            listview.lastSelectedIndex = index;
                        }
                    } else if (mouse.button == Qt.RightButton) {
                        if ((mouse.modifiers != Qt.ControlModifier) && !selected) {
                            listview.selectedIds = [identifier];
                        }
                        listview.lastSelectedIndex = index;
                    }
                    listview.selectedIds = [...new Set(listview.selectedIds)];
                    listview.updateSelection();
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
        propagateComposedEvents: true
        onClicked: {
            listview.selectedIds = [];
            listview.updateSelection();
        }
    }
}
