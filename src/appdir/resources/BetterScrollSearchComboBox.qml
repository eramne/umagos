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
            color: "transparent"
        }

        contentItem: ScrollView {
            implicitHeight: contentHeight
            implicitWidth: contentWidth

            BetterScrollListView {
                id: listview
                clip: true
                implicitHeight: contentHeight
                implicitWidth: contentWidth
                model: filteredDelegateModel
                currentIndex: combobox.highlightedIndex
                delegate: filteredDelegateModel.delegate
            }
        }
    }
}
