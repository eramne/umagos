import QtQuick 2.14
import QtQuick.Controls 2.3

BetterScrollListView {
    id: listview
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

    function select(index, button = Qt.LeftButton, modifiers = Qt.NoModifier) {
        var identifier = listview.idOf(index);
        if (button === Qt.LeftButton) {
            if (!(modifiers & Qt.ControlModifier) && !(modifiers & Qt.ShiftModifier)) {
                listview.selectedIds = [identifier];
                listview.lastSelectedIndex = index;
            }

            if (modifiers & Qt.ControlModifier) {
                if (!listview.getSelected(index)) {
                    listview.selectedIds.push(identifier);
                } else {
                    const indexToRemove = listview.selectedIds.indexOf(identifier);
                    if (indexToRemove > -1) {
                        listview.selectedIds.splice(indexToRemove, 1);
                    }
                }
            }
            if (modifiers & Qt.ShiftModifier) {
                if (!(modifiers & Qt.ControlModifier)) {
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
        } else if (button === Qt.RightButton) {
            if ((modifiers !== Qt.ControlModifier) && !listview.getSelected(index)) {
                listview.selectedIds = [identifier];
            }
            listview.lastSelectedIndex = index;
        }
        listview.selectedIds = [...new Set(listview.selectedIds)];
        listview.selectionUpdated();
    }

    model: ListModel {
        id: listmodel
    }

    MouseArea {
        anchors.fill: parent
        z: -1
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        propagateComposedEvents: true
        onClicked: {
            var mappedPoint = listview.contentItem.mapFromItem(this, mouse.x, mouse.y);
            var clickedIndex = listview.indexAt(listview.x, mappedPoint.y);
            if (clickedIndex === -1) {
                listview.selectedIds.length = 0;
                listview.selectionUpdated();
            } else {
                listview.select(clickedIndex, mouse.button, mouse.modifiers);
            }
        }
    }
}
