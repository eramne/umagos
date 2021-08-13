import QtQuick 2.14
import QtQuick.Controls 2.3

ListView {
    id: listview
    visible: true
    interactive: false
    flickableDirection: Flickable.HorizontalAndVerticalFlick
    property real sensitivity: 1/3

    function scroll(x, y) {
        parent.ScrollBar.vertical.active = true;
        parent.ScrollBar.horizontal.active = true;
        listview.contentX -= x;
        listview.contentY -= y;
        listview.returnToBounds();
        listview.contentX -= listview.horizontalOvershoot;
        listview.contentY -= listview.verticalOvershoot;
        parent.ScrollBar.vertical.active = false;
        parent.ScrollBar.horizontal.active = false;
    }

    function scrollToBottom() {
        parent.ScrollBar.vertical.position = 1.0 - parent.ScrollBar.vertical.size;
        parent.ScrollBar.horizontal.position = 0;
        scroll(0, 0);
    }

    WheelHandler {
        target: listview.parent
        onWheel: {
            var delta = event.hasPixelDelta ? event.pixelDelta : event.angleDelta;
            if (event.modifiers & Qt.ShiftModifier) {
                listview.scroll(delta.y*sensitivity);
            } else {
                listview.scroll(delta.x*sensitivity, delta.y*sensitivity);
            }
        }
    }
}
