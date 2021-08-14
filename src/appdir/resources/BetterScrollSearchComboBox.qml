import QtQuick 2.14
import QtQuick.Controls 2.3
import QtQml.Models 2.2

SearchComboBox {
    id: combobox

    popup: Popup {
        width: combobox.width
        implicitHeight: contentItem.implicitHeight
        padding: 1

        background: Rectangle {
            anchors.fill: parent
            border.color: "black"
            border.width: 1
            color: "white"
        }

        Rectangle {
            x: listview._wheelhandler.parent.x
            y: listview._wheelhandler.parent.y
            width: listview._wheelhandler.parent.width
            height: listview._wheelhandler.parent.height
            color: "#5500ff00"
        }

        Rectangle {
            anchors.fill: parent.contentItem
            border.color: "red"
            border.width: 1
            color: "#88ff0000"
            z: 9999
        }

        contentItem: ScrollView {
            onContentHeightChanged: {
                parent.height = contentHeight;
            }

            BetterScrollListView {
                id: listview
                clip: true
                model: combobox.filteredDelegateModel
                currentIndex: combobox.highlightedIndex
                delegate: combobox.filteredDelegateModel.delegate
            }
        }
    }
}
