import QtQuick 2.14
import QtQuick.Controls 2.3

BetterScrollListView {
    id: listview
    property Component rowDelegate: Component { Item {} }
    property Component highlightItem: Component {
        Rectangle {
            color: listview.activeFocus ? "#aaaaff" : "#cccccc"
        }
    }
    property var selectedIds: []
    property int lastSelectedIndex: -1
    highlightFollowsCurrentItem: false

    onSelectedIdsChanged: {
        listview.selectionUpdated();
    }

    signal selectionUpdated()

    onSelectionUpdated: {
        //remove all duplicates and items that no longer exist
        var newIds = [];
        for (var i = 0; i < listview.selectedIds.length; i++) {
            var _id = listview.selectedIds[i];
            if (!newIds.includes(_id) && listview.indexOf(_id) !== -1) {
                newIds.push(_id);
            }
        }
        if (newIds.length !== listview.selectedIds.length) {
            listview.selectedIds = newIds;
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
        if (typeof listview.model.get(_index) === 'undefined') {
            return -1;
        }
        var _id = listview.model.get(_index).id;
        return typeof _id === 'undefined' ? _index : _id;
    }

    function getSelected(_index) {
        return listview.selectedIds.includes(idOf(_index));
    }

    model: ListModel {
        id: listmodel
    }
    delegate: Item {
        id: rowItem
        property var identifier: typeof model.id === 'undefined' ? index : model.id
        width: loader.item.width
        height: loader.item.height
        property bool selected: false
        property alias contentItem: loader.item

        Component.onCompleted: {
            if (typeof listview !== 'undefined') {
                rowItem.selected = listview.getSelected(index);
            }
            listview.selectionUpdated.connect(function () {
                if (typeof listview !== 'undefined') {
                    rowItem.selected = listview.getSelected(index);
                }
            });
        }
        Item {
            height: rowItem.height
            width: Math.max(listview.width, listview.contentWidth)
            opacity: rowItem.selected ? 1 : 0

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
                    listview.selectionUpdated();
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
            listview.selectedIds.length = 0;
            listview.selectionUpdated();
        }
    }
}
