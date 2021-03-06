import QtQuick 2.4
import ".." 1.0
import "../.." 1.0

Rectangle {

    id: button

    width: Math.max(label.width + 6, 32)
    height: 12

    property alias text: label.text
    property alias mouseArea: ma
    property int textColor: 7
    signal clicked()

    color: ma.containsMouse? "#888" : "#333"

    border.color: "#88aa00"
    border.width: 1


    DWTextBitmap
    {
        id: label
        anchors.centerIn: parent

        font: "xexex-multi"
        offset: 95*textColor

    }


    MouseArea
    {
        id: ma
        anchors.fill: parent
        hoverEnabled: true

        onClicked: button.clicked()
    }

}

