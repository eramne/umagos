import QtQuick 2.14
import QtQuick.Window 2.14
import QtQuick.Controls 2.3

Flickable {
    id: flickable
    visible: true
    interactive: false
    flickableDirection: Flickable.HorizontalAndVerticalFlick
    property real sensitivity: 1

    function scroll(val, horiz = false) {
        var scrollbar = horiz ? parent.ScrollBar.horizontal : parent.ScrollBar.vertical;
        //scrollbar.position -= val;
        scrollbar.stepSize = val;
        scrollbar.decrease();
        scrollbar.stepSize = 0;
        flickable.returnToBounds();
        flickable.contentX -= flickable.horizontalOvershoot;
        flickable.contentY -= flickable.verticalOvershoot;
    }

    WheelHandler {
        target: flickable.parent
        onWheel: {
            var delta = event.hasPixelDelta ? event.pixelDelta : event.angleDelta;
            if (event.modifiers & Qt.ShiftModifier) {
                flickable.scroll((delta.y/3000)*sensitivity, true)
            } else {
                flickable.scroll((delta.y/3000)*sensitivity)
            }
        }
    }
}
