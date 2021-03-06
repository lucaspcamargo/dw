import QtQuick 2.4
import ".."

Image {


    property var buttonInstructions: [ ['⏎ ', "Start Game"] ]

    source: resBase + "ui/title/title-1080.png"
    fillMode: Image.PreserveAspectCrop

    Component.onCompleted: forceActiveFocus();

    Keys.onReturnPressed: {
        startGame();
        event.accepted = true;
    }

    function startGame() {
        if(startGameTimer.running) return;
        titleBgm.destroy();
        sfx.play();
        startGameTimer.start();
    }

    Timer
    {
        id: startGameTimer
        interval: 750
        onTriggered:
        {
            mainScreenBgm.play();
            mainScreen.stack(Qt.resolvedUrl("DWMainMenu.qml"));
        }
    }

    MouseArea
    {
        anchors.fill: parent
        onClicked: startGame();
    }


    DWSoundEffect
    {
        id: sfx
        gain: 2
        source: resBase + "ui/title/start.ogg"
    }

}

