import QtQuick 2.0

Row {
    id: row
    property string text: ""
    property string font: "chaotix-hud"
    property bool asyncronous: true
    property bool active: visible
    property int offset: 0

    Repeater {        
        model: active? text.length : null

        Image {
            source: "fonts/"+font+"/" + (text.charCodeAt(index)+offset) + ".png"
            smooth: false
            antialiasing: false
            asynchronous: row.asyncronous
        }
    }
}
