import QtQuick 2.14
import QtQuick.Window 2.14
import QtQuick.Controls 2.3

Flickable {
    id: flickable
    visible: true
    interactive: false
    flickableDirection: Flickable.HorizontalAndVerticalFlick
    property real sensitivity: 1/3

    function scroll(x, y) {
        parent.ScrollBar.vertical.active = true;
        parent.ScrollBar.horizontal.active = true;
        flickable.contentX -= x;
        flickable.contentY -= y;
        flickable.returnToBounds();
        flickable.contentX -= flickable.horizontalOvershoot;
        flickable.contentY -= flickable.verticalOvershoot;
        parent.ScrollBar.vertical.active = false;
        parent.ScrollBar.horizontal.active = false;
    }

    function scrollToBottom() {
        parent.ScrollBar.vertical.position = 1.0 - parent.ScrollBar.vertical.size;
        parent.ScrollBar.horizontal.position = 0;
        scroll(0, 0)
    }

    WheelHandler {
        target: flickable.parent
        onWheel: {
            var delta = event.hasPixelDelta ? event.pixelDelta : event.angleDelta;
            if (event.modifiers & Qt.ShiftModifier) {
                flickable.scroll(delta.y*sensitivity);
            } else {
                flickable.scroll(delta.x*sensitivity, delta.y*sensitivity);
            }
        }
    }
}
