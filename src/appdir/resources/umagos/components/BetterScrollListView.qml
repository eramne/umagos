import QtQuick 2.14
import QtQuick.Controls 2.3

ListView {
    id: listview
    visible: true
    interactive: false
    flickableDirection: Flickable.HorizontalAndVerticalFlick
    highlightMoveDuration: -1
    highlightMoveVelocity: -1
    maximumFlickVelocity: 0

    property real sensitivity: 2/3
    property real maxVelocity: 100
    property real targetX: 0
    property real targetY: 0

    Timer {
        interval: 1000/60
        running: contentY !== targetY || contentX !== targetX
        repeat: true
        onTriggered: {
            var velX = Math.ceil((listview.contentX - listview.targetX)/10);
            var velY = Math.ceil((listview.contentY - listview.targetY)/10);
            listview.scroll(velX, velY);
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
        listview.contentX -= x;
        listview.contentY -= y;

        var resetTargetY = false
        if (listview.verticalOvershoot != 0) {
            resetTargetY = true
        }
        var resetTargetX = false
        if (listview.horizontalOvershoot != 0) {
            resetTargetX = true
        }

        listview.returnToBounds();
        listview.contentX -= listview.horizontalOvershoot;
        listview.contentY -= listview.verticalOvershoot;

        if (resetTargetY) {
            listview.targetY = listview.contentY;
        }
        if (resetTargetX) {
            listview.targetX = listview.contentX;
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
        listview.currentIndex = listview.model.count - 1;
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
                        listview.targetX -= delta.y*sensitivity;
                    } else {
                        listview.targetX -= delta.x*sensitivity;
                        listview.targetY -= delta.y*sensitivity;
                    }
                } else {
                    if (event.modifiers & Qt.ShiftModifier) {
                        listview.targetX -= delta.x*sensitivity;
                        listview.targetY -= delta.y*sensitivity;
                    } else {
                        listview.targetX -= delta.y*sensitivity;
                    }
                }
            }
        }
    }
}
