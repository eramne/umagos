import QtQuick 2.14
import QtQuick.Controls 2.3

BetterScrollListView {
    id: listview
    property Component rowDelegate: Component { Item {} }
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

        Item {
            height: rowItem.height
            width: Math.max(listview.width, listview.contentWidth)
            opacity: selected ? 1 : 0

            Rectangle {
                anchors.fill: parent
                color: "#aaaaff"
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
                            listview.selectedIndices.push(index);
                            listview.selectedIndices = [...new Set(listview.selectedIndices)]; //remove duplicates
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
                            listview.selectedIndices = [...new Set(listview.selectedIndices)]; //remove duplicates
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
                }
            }
        }

        Loader {
            sourceComponent: listview.rowDelegate
            id: loader
            property var itemData: Object.assign({}, listmodel.get(index));
            property int index: model.index
        }

        /*Item {
            id: contentItem
            Row {
                padding: 5
                Text {
                    text: name
                    anchors.verticalCenter: parent.verticalCenter
                    font.pixelSize: 12
                }
            }
        }*/
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
