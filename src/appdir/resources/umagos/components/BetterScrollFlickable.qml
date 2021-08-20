import QtQuick 2.14
import QtQuick.Controls 2.3

Flickable {
    id: flickable
    visible: true
    interactive: false
    flickableDirection: Flickable.HorizontalAndVerticalFlick
    maximumFlickVelocity: 0

    property real sensitivity: 1/2
    property real easeSpeed: 1/5
    property real targetX: 0
    property real targetY: 0

    Timer {
        interval: 1000/60
        running: contentY !== targetY || contentX !== targetX
        repeat: true
        onTriggered: {
            var velX = Math.ceil((flickable.contentX - flickable.targetX)*easeSpeed);
            var velY = Math.ceil((flickable.contentY - flickable.targetY)*easeSpeed);
            flickable.scroll(velX, velY);
        }
    }

    Component.onCompleted: {
        if (parent instanceof ScrollView) {
            parent.ScrollBar.horizontal.onPositionChanged.connect(function () {
                if (parent.ScrollBar.horizontal.pressed) {
                    targetX = contentX;
                }
            });
            parent.ScrollBar.vertical.onPositionChanged.connect(function () {
                if (parent.ScrollBar.vertical.pressed) {
                    targetY = contentY;
                }
            });
        }
    }

    function scroll(x, y) {
        if (parent instanceof ScrollView) {
            parent.ScrollBar.vertical.active = true;
            parent.ScrollBar.horizontal.active = true;
        }
        flickable.contentX -= x;
        flickable.contentY -= y;

        var resetTargetY = false
        if (flickable.verticalOvershoot != 0) {
            resetTargetY = true
        }
        var resetTargetX = false
        if (flickable.horizontalOvershoot != 0) {
            resetTargetX = true
        }

        flickable.returnToBounds();
        flickable.contentX -= flickable.horizontalOvershoot;
        flickable.contentY -= flickable.verticalOvershoot;

        if (resetTargetY) {
            flickable.targetY = flickable.contentY;
        }
        if (resetTargetX) {
            flickable.targetX = flickable.contentX;
        }

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
        flickable.targetY = flickable.contentHeight;
        if (parent instanceof ScrollView) {
            parent.ScrollBar.vertical.active = false;
            parent.ScrollBar.horizontal.active = false;
        }
    }
    Item {
        anchors.fill: parent
        WheelHandler {
            target: flickable.parent

            onWheel: {
                var delta = event.hasPixelDelta ? event.pixelDelta : event.angleDelta;
                if (event.modifiers & Qt.ShiftModifier) {
                    flickable.targetX -= delta.y*sensitivity;
                } else {
                    flickable.targetX -= delta.x*sensitivity;
                    flickable.targetY -= delta.y*sensitivity;
                }
            }
        }
    }
}
