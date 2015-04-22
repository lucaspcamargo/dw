import QtQuick 2.3
import QtMultimedia 5.0
import dw 1.0
import "tools" 1.0

Item {
    id: scene
    anchors.fill: parent

    property url levelFile: "mm/mm.json"
    property var levelData: (JSON.parse(DWUtil.readTextFile(levelFile)))

    Item
    {
        id: fieldContainer

        height: 240
        scale: parent.height / height
        width: height * parent.width/parent.height
        anchors.centerIn: parent

        Rectangle
        {
            id: bgColor
            z: field.bgZ - 1
            anchors.fill: parent
            visible: levelData.bgColor? true : false
            Component.onCompleted:
            {
                if(visible)
                    color = levelData.bgColor;
                else
                    bgColor.destroy();
            }
        }

        DWLevelBackground {
            id: bg
            inPrefix: true
        }

        Image
        {
            id: editorCheckerboard
            anchors.fill: parent
            source: "etc/transparent.png"
            fillMode: Image.Tile
            visible: levelEditor.visible
        }

        DWLevelField {
            id: field
        }

        Image
        {
            id: hurtOverlay
            source: "field/fx/hurt-overlay.png"
            anchors.fill: parent
            opacity: 0

            function playAnimation(){ hurtOverlayAnim.start() }

            SequentialAnimation
            {
                id: hurtOverlayAnim
                running: false

                PropertyAction
                {
                    target: hurtOverlay
                    property: "opacity"
                    value: 0.75
                }

                PropertyAnimation
                {
                    target: hurtOverlay
                    property: "opacity"
                    to: 0.0
                }

            }
        }

        Image
        {
            id: drownOverlay
            source: "field/fx/drown-overlay.png"
            anchors.fill: parent
            opacity: 0

            Behavior on opacity { NumberAnimation {} }

            SequentialAnimation
            {
                id: drownOverlayAnim
                running: false

                PropertyAnimation
                {
                    target: drownOverlay
                    property: "opacity"
                    to: 1.0
                    duration: 12000
                }

            }
        }

        DWHud
        {
            id: hud
            anchors.fill: parent

            z: field.hudZ

            timeValue: field.fieldTime
        }

    }

    DWLevelBGMPlayer
    {
        id: bgmPlayer
    }

    Component.onCompleted:
    {
        offscreen = true;
        if(_DW_DEBUG) controls.escapePressed.connect(levelEditor.toggleVisible);
    }


    DWControls
    {
        id: controls
        anchors.centerIn: parent
        height: 900
        width: height * parent.width/parent.height
        scale: parent.height / height
        focus: true
        visible: _DW_MOBILE

        dPadMode: true
    }

    Rectangle
    {
        id: sceneFader
        color: "black"
        anchors.fill: parent
        visible: opacity != 0

        Behavior on opacity { NumberAnimation{duration: 500}}
    }


    Item
    {
        id: sceneTitle
        anchors.fill: parent

        property int animDuration: 750

        Image
        {
            id: titleDecoration
            source: "ui/titlecards/tile.png"
            height: parent.height * 20
            fillMode: Image.TileVertically

            x: -width
            Behavior on x { NumberAnimation { easing.type: Easing.InOutQuart; duration: sceneTitle.animDuration } }


            NumberAnimation on y{
                duration: 400
                from: 0
                to: -24
                easing.type: Easing.Linear
                running: true
                loops: Animation.Infinite
            }

        }

        Rectangle
        {
            id: titleShadow
            width: parent.width
            height: 96 + (levelData.subtitle? 8 : 0 )

            y: 240
            color: "#222"
            opacity: 0.7

            Behavior on y { NumberAnimation { easing.type: Easing.InOutQuart; duration: sceneTitle.animDuration } }

        }

        DWTextBitmap
        {
            id: subtitle
            x: 128 + 4
            anchors.bottom: titleShadow.bottom
            anchors.bottomMargin: 6
            font: "xexex-multi"
            text: levelData.subtitle
        }

        Image
        {
            id: title
            x: 427
            anchors.verticalCenter: parent.verticalCenter

            source: Qt.resolvedUrl(levelData.urlPrefix + "title.png")

            Behavior on x { NumberAnimation { easing.type: Easing.InOutQuart; duration: sceneTitle.animDuration } }
        }

    }

    property int frame: 0
    DWEveryFrame
    {
        onUpdate:
        {
            if(frame == 1)
                field.init();

            if(frame == 2)
                titleAnimation.running = true;

            frame++;
        }
    }

    SequentialAnimation
    {
        id: titleAnimation

        property int bgmIndexToPlay: 0
        property real timeToResetTo: 0

        running: false

        ScriptAction {
            script:
            {
                field.fieldActive = true;

                sceneTitle.visible = true;
                sceneTitle.animDuration = 750;
                globalFader.opacity = 0;
                title.x = 128 + 4
                titleDecoration.x = 0
                titleShadow.y = 120 - 48
            }
        }

        PauseAnimation {
            duration: sceneTitle.animDuration
        }

        ScriptAction {
            script:
            {
                bgmPlayer.currentBGM = titleAnimation.bgmIndexToPlay;
                bgmPlayer.resetBGM( bgmPlayer.currentBGM );
            }
        }


        PauseAnimation {
            duration: 1500
        }

        ScriptAction {
            script: { sceneFader.opacity = 0;}
        }

        PauseAnimation {
            duration: 500
        }

        ScriptAction {
            script:
            {
                field.fieldTime = titleAnimation.timeToResetTo;
                controls.keyboardHandler.forceActiveFocus();

                dwLogo.visible = true;

                sceneTitle.animDuration = 300;
            }
        }

        PauseAnimation {
            duration: 500
        }

        ScriptAction {
            script:
            {
                title.x = 427
                titleDecoration.x = -titleDecoration.width
                titleShadow.y = 240
            }
        }

        PauseAnimation {
            duration: sceneTitle.animDuration
        }

        ScriptAction {
            script:
            {
                sceneTitle.visible = false;
                sceneTitle.animDuration = 750;
            }
        }


    }

    DWLevelEditor
    {
        id: levelEditor
        Component.onCompleted: { if(!_DW_DEBUG) { editorCheckerboard.destroy(); levelEditor.destroy(); } }
    }

    DWTextBitmap
    {
        id: fpsCounter
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.margins: 10
        font: "xexex-multi"
        text: visible? DWRoot.profilerFPS.toFixed(2) : ""
        visible: _DW_DEBUG
    }

    DWTextBitmap
    {
        id: worstFpsCounter
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.margins: 10
        anchors.bottomMargin: 20
        font: "xexex-multi"; offset: (visible && DWRoot.profilerWorstFrameTime > 0.010)? 5*95: 0
        text: visible? (DWRoot.profilerWorstFrameTime * 1000).toFixed(2) : ""
        visible: _DW_DEBUG
    }

    DWTextBitmap
    {
        id: frameTimeCounter
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.margins: 10
        anchors.bottomMargin: 30
        font: "xexex-multi";
        text: visible? (DWRoot.profilerFrameTime * 1000).toFixed(2) : ""
        visible: _DW_DEBUG
    }

}
