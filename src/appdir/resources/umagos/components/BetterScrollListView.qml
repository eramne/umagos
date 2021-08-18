import QtQuick 2.14
import QtQuick.Controls 2.3

ListView {
    id: listview
    visible: true
    interactive: false
    flickableDirection: Flickable.HorizontalAndVerticalFlick
    highlightMoveDuration: 0
    property real sensitivity: 1/3
    maximumFlickVelocity: 0

    function scroll(x, y) {
        if (parent instanceof ScrollView) {
            parent.ScrollBar.vertical.active = true;
            parent.ScrollBar.horizontal.active = true;
        }
        listview.contentX -= x;
        listview.contentY -= y;
        listview.returnToBounds();
        listview.contentX -= listview.horizontalOvershoot;
        listview.contentY -= listview.verticalOvershoot;
        if (parent instanceof ScrollView) {
            parent.ScrollBar.vertical.active = false;
            parent.ScrollBar.horizontal.active = false;
        }
    }

    function scrollToBottom() {
        if (parent instanceof ScrollView) {
            parent.ScrollBar.vertical.active = true;
            parent.ScrollBar.horizontal.active = true;
        }
        currentIndex = count - 1;
        if (parent instanceof ScrollView) {
            parent.ScrollBar.vertical.active = false;
            parent.ScrollBar.horizontal.active = false;
        }
    }
    Item {
        anchors.fill: parent
        WheelHandler {
            target: listview.parent

            onWheel: {
                var delta = event.hasPixelDelta ? event.pixelDelta : event.angleDelta;
                if (listview.orientation === ListView.Vertical) {
                    if (event.modifiers & Qt.ShiftModifier) {
                        listview.scroll(delta.y*sensitivity);
                    } else {
                        listview.scroll(delta.x*sensitivity, delta.y*sensitivity);
                    }
                } else {
                    if (event.modifiers & Qt.ShiftModifier) {
                        listview.scroll(delta.x*sensitivity, delta.y*sensitivity);
                    } else {
                        listview.scroll(delta.y*sensitivity);
                    }
                }
            }
        }
    }
}
