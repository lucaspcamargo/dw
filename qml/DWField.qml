import QtQuick 2.3

Item {

    id: fieldBase
    enabled: false // do no receive any sort of input event

    property int viewWidth: parent.width / viewScale
    property int viewHeight: parent.height / viewScale
    property real viewCenterAtX: 0
    property real viewCenterAtY: 0

    property real viewRadius: Qt.vector2d(viewWidth/2, viewHeight/2).length() / viewScale

    property real viewScale: 1
    scale: viewScale
    transformOrigin: Item.TopLeft

    x: /*Math.floor*/ (viewScale*(-viewCenterAtX + viewWidth/2))
    y: /*Math.floor*/ (viewScale*(-viewCenterAtY + viewHeight/2))
    property real absoluteXDelta: (-x)/viewScale
    property real absoluteYDelta: (-y)/viewScale

}
