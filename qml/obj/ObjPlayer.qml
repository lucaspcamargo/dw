import QtQuick 2.3
import QtMultimedia 5.0
import dw 1.0
import ".." 1.0

DWPlayerBase {

    id: player
    z: field.playerZ


    // PHYSICS COLLIDER

    DWFOPhysicsBody {

        id: physicsBody

        bodyType: DWFOPhysicsBody.BT_KINEMATIC
        shapeType: DWFOPhysicsBody.ST_POLY_BOX
        shapeCategory: DWFieldPhysicsWorld.CC_PLAYER
        shapeCollisionMask: DWFieldPhysicsWorld.CC_DYNAMIC | DWFieldPhysicsWorld.CC_GIB | DWFieldPhysicsWorld.CC_PLAYER_SENSOR

        shapeData: Qt.vector4d(playerHalfWidth, playerHalfHeight, 0, 0)
    }

    // SPRITE AND ANIMS

    property string currentAnimation: ""


    Item{
        id: spriteManipulator

        rotation: Math.round( (currentAnimation == "rolling" || currentAnimation == "rollingM"? 0 : gAngle) / 0.001) * 0.001

        x: 0//- ( player.x - Math.round(player.x))
        y: 0//- ( player.y - Math.round(player.y))

        DWSprite
        {
            id: sprite
            spritesheet: resBase + "obj/player/sonic-cd-xbr4x.dws?standing"
            running: true
            x: -width / 2
            y: -height + playerHalfHeight // + (currentAnimation == "falling"? 5 : 0) (Math.abs(Math.sin(gAngleRad + Math.PI / 4)) + Math.abs(Math.cos(gAngleRad + Math.PI / 4)))
            height: 48
            width: 48

            transform: Rotation{

                origin.x: sprite.width/2
                origin.y: sprite.height
                axis{ x:0; y:1; z:0 }
                angle: (turnedBack )? 180 : 0
            }

        }
    }


    // SHIELDS
    property bool hasShield: false
    property int shieldType: 0
    property int shieldTypeCount: 4
    property var shield: null
    property var shields: []

    onHasShieldChanged:
    {
        if(hasShield)
        {
            shield = shields[shieldType];
            shield.visible = true;
            if(shield.update)
                shield.update();
        }else
        {
            shield.visible = false;
            shield = null;
        }
    }

    onShieldTypeChanged:
    {
        if(shieldType >= shieldTypeCount)
        {
            shieldType = 0;
            hasShield = false;
        }
        else
        {
            if(hasShield)
            {
                hasShield = false;
                hasShield = true;
            }
        }
    }



    //MIDAIR CONTROL

    property bool canUseMidair: false

    onPlayerJumpingChanged:
    {
        if(playerJumping)
        {
            canUseMidair = true;
        }
    }

    onPlayerStateChanged:
    {
        if(playerState == DWPlayerBase.PS_GROUND)
        {
            canUseMidair = false;
        }
    }

    onJumpedInMidair:
    {
        if(!canUseMidair) return;

        if(hasShield)
        {
            if(shield.action)
            {
                shield.action();
                canUseMidair = false;
            }
        }
    }


    // PPT

    property bool rememberPreviousPos: false
    property var previousX: [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0] // 64 zeros
    property var previousY: [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0] // 64 zeros
    property int previousPosIndex: 0
    property int previousPosTotal: 64

    Repeater
    {
        model: (_DW_DEBUG && _DW_DEBUG_PHYSICS_DRAW && rememberPreviousPos)? previousPosTotal / 4 : 0

        Rectangle
        {
            width: 8 * opacity
            height: 8 * opacity
            radius: width / 2
            x: previousX[(previousPosIndex + 4*index) % previousPosTotal] - player.x - radius
            y: previousY[(previousPosIndex + 4*index) % previousPosTotal] - player.y - radius
            opacity: index / previousPosTotal * 4
            color: Qt.rgba(1 , 1, 1 - opacity, 1.0)
        }
    }

    // WATER

    property bool inWater: field.water && y > field.waterY

    property real bubbleTimeAccum: 0
    property real bubbleTimeToNextBubble: 2

    property int secsInWater: 0
    property int waterCountdownLimit: 18

    onInWaterChanged:
    {
        recalcPhysicsVariables(inWater);
        if(inWater)
        {
            if( hasShield && (shieldType == 1 || shieldType == 3 ) )
            {
                shield.playWaterLossSfx();
                waterFlasherAnimation.running = shieldType == 1;
                hasShield = false;
            }

            xSpeed *= 0.5;
            ySpeed *= 0.25;
        }
        else
        {
            fieldController.playerDrowning = false;
            secsInWater = 0;
            ySpeed *= 2;
        }

        if(field.fieldActive) waterSfx.play();
        field.createWaterSplash(x);

        bgmPlayer.underwater = inWater;
    }

    function breathe()
    {
        breatheSfx.play();
        ySpeed = 0;
        xSpeed = 0;
        gSpeed = 0;
        playerRolling = false;
        if(playerState == DWPlayerBase.PS_AIR)
            setAnimation("falling");

        fieldController.playerDrowning = false;
        secsInWater = 0;
        underwaterTimer.restart();
    }

    Timer
    {
        id: underwaterTimer
        interval: 1000
        repeat: true
        running: field.fieldActive && active && inWater && !playerDead
        onTriggered: secsInWater++
    }

    onSecsInWaterChanged:
    {
        if( secsInWater == waterCountdownLimit )
        {
            fieldController.playerDrowning = true;
        }
        else if( (secsInWater != 0) && (secsInWater < waterCountdownLimit) && (secsInWater % 5 == 0) )
            waterWarningSfx.play();
        else if( secsInWater == waterCountdownLimit + 13 )
        {
            die(true);
        }

    }



    // MISC ESSENTIALS

    property bool playerDead: false
    property bool playerHarmful: player.playerRolling || player.currentAnimation == "spindash"

    DWEveryFrame
    {
        id: debugFly

        enabled: _DW_DEBUG && (fieldController.paused)

        onEnabledChanged: {
            field.viewScale = enabled? (1/3) : 1;
            fieldBVH.viewRadius *= enabled? 3 : (1/3);
            //rootWindow.offscreen = !enabled;
        }

        onUpdate: {
            x += controls.directionValueX * dt * (controls.bPressed? 1200: 600);
            y -= controls.directionValueY * dt * (controls.bPressed? 1200: 600);
        }
    }

    // we need to process getting hit on object update, not in physics step
    property bool hitFlag: false

    onGotHit:
    {
            hitFlag = true;
    }

    function handleHit()
    {
        hurtOverlay.playAnimation()

        if(hasShield)
        {
            hasShield = false;
            hurtSfx.play();
            return;
        }

        var amount = Math.min(fieldController.rings, 32);
        fieldController.rings = 0;

        if(amount == 0)
        {
            die();
            return;
        }

        if(amount)ringLossSfx.play();
        else hurtSfx.play();

        var c = Qt.createComponent("ObjRing.qml");

        // from the SONIC RETRO SPG
        var t = 0;
        var angle = 101.25;  //assuming 0=right, 90=up, 180=left, 270=down
        var n = false;
        var speed = convertGenesisSpeed(4);

        while( t < amount )
        {
            var o = c.createObject(parent); //create a bouncing ring object
            o.x = x-8;
            o.y = y-8;
            o.flying = true;
            o.yS = -Math.sin(angle)*speed; //set the ring's vertical speed to -sine(angle)*speed
            o.xS = -Math.cos(angle)*speed; //set the ring's horizontal speed to cosine(angle)*speed
            if(n)
            {
                o.xS *= -1; //multiply the ring's horizontal speed by -1
                angle += 22.5;
            }
            n = !n; //if n is false, n becomes true and vice versa
            t++; //increase t by 1
            if (t == 16)
            {
                speed = convertGenesisSpeed(2); //we're on the second circle now, so decrease the speed
                angle = 101.25; //and reset the angle
            }
        }
    }

    function die( drowned )
    {
        setAnimation(drowned? "drowned" : "dead");

        playerDead = true;
        hasShield = false;

        field.fieldActive = false;
        xSpeed = 0;
        ySpeed = inWater? 0 : convertGenesisSpeed(-7);
        z = fgZ;

        if(drowned)
            drownSfx.play();
        else
            hurtSfx.play();

        fieldController.playerDied();
    }

    function reset()
    {
        if(invincibility.running) invincibility.complete();

        active = true;
        playerDead = false;

        setAnimation("falling");

        player.hasShield = false;
        player.turnedBack = false;
        player.playerQuadModeLocked = false;

        player.xSpeed = 0;
        player.ySpeed = 0;
        player.gSpeed = 0;
        player.playerRolling = false;

        player.z = field.playerZ;
    }

    onAnimationChanged:
    {
        if(playerDead) return;

        currentAnimation = animation;

        sprite.sequence = animation;
    }


    Component.onCompleted:
    {
        physicsBody.rebuildBody();

        setAnimation("standing");

        // create shields
        for(var chupa = 0; chupa < shieldTypeCount; chupa ++)
        {
            var meu = Qt.createComponent("player/Shield"+chupa+".qml");
            var pau = meu.createObject(this);

            shields[chupa] = pau;
        }

    }

    property real animFramesAccum: 0

    function update(dt)
    {
        if(hitFlag)
        {
            hitFlag = false;
            handleHit();
        }

        if(!playerDead)
        {
            injectControl(controls.directionValueX, controls.directionValueY, controls.aPressed, controls.bPressed);
            numIterations = Math.max( Math.round(dt/0.01666666), 2 ) * (playerQuadModeVertical? 2 : 1);
            player.updateSim(dt);
            physicsBody.rebuildBody();
        }
        else
        {
            ySpeed += player.getCurrentGravity() * dt;
            if(y < (field.viewCenterAtY + field.viewHeight/2 + 40) ) y += ySpeed * dt;
        }

        if((currentAnimation == "walking" || currentAnimation == "rollingM" ) )
        {
            animFramesAccum += 1;
            if(animFramesAccum >= Math.max((currentAnimation == "rollingM"? 4 : 8) - Math.round(Math.abs(gSpeed/60)), 1))
            {
                sprite.advanceFrame();
                animFramesAccum = 0;
            }
        }

        if(inWater && playerQuadMode == 0)
        {
            if(!playerRolling)
            {
                bubbleTimeAccum += dt;
                if(bubbleTimeAccum > bubbleTimeToNextBubble)
                {
                    bubbleTimeToNextBubble = 0.25 + Math.random() * 0.5;
                    bubbleTimeAccum = 0;

                    var c = Qt.createComponent("ObjBubble.qml");
                    var o = c.createObject(field);
                    o.x = x + (turnedBack? -8 : 8);
                    o.y = y - 8;
                    o.sizeLimit = Math.round(Math.random()*2);
                    o.timeToFullSize = 0.75
                }
            }
        }

        if(hasShield && shield.update)
            shield.update(dt);

        if(rememberPreviousPos)
        {
            previousPosIndex = (previousPosIndex + 1) % previousPosTotal;
            previousX[previousPosIndex] = x;
            previousY[previousPosIndex] = y;
        }
    }


    onPlaySfx:
    {
        if(sfx == "brake") brakeSfx.play();
        else if(sfx == "land" && !inWater) landSfx.play();
        else if(sfx == "jump") jumpSfx.play();
        else if(sfx == "speed") speedSfx.play(1.0, pitch);
        else if(sfx == "ringLoss") ringLossSfx.play();
        else if(sfx == "peelout") peeloutSfx.play(); //1.0, playerSpindash > 0? 1 + playerSpindash : 1.0);
        else if(sfx == "peeloutCharge") peeloutChargeSfx.play();
        else if(sfx == "ready") readySfx.play();
    }

    DWSoundEffect
    {
        id: brakeSfx
        source: resBase + "obj/player/sfx/brake-sa.wav.ogg"
    }

    DWSoundEffect
    {
        id: jumpSfx
        source: resBase + "obj/player/sfx/jump.wav.ogg"
    }

    DWSoundEffect
    {
        id: speedSfx
        source: resBase + "obj/player/sfx/speed.wav.ogg"
        gain: 0.2
    }

    DWSoundEffect
    {
        id: ringLossSfx
        source: resBase + "obj/player/sfx/lostrings.wav.ogg"
    }

    DWSoundEffect
    {
        id: peeloutSfx
        source: resBase + "obj/player/sfx/peelout.wav.ogg"
    }

    DWSoundEffect
    {
        id: peeloutChargeSfx
        source: resBase + "obj/player/sfx/peeloutCharge.wav.ogg"
        gain: 0.5
    }

    DWSoundEffect
    {
        id: hurtSfx
        source: resBase + "obj/player/sfx/no.wav.ogg"
        gain: 2
    }

    DWSoundEffect
    {
        id: waterSfx
        source: resBase + "obj/player/sfx/water.wav.ogg"
    }

    DWSoundEffect
    {
        id: waterWarningSfx
        source: resBase + "obj/player/sfx/water-warning.wav.ogg"
    }

    DWSoundEffect
    {
        id: breatheSfx
        source: resBase + "obj/player/sfx/breathe.wav.ogg"
    }

    DWSoundEffect
    {
        id: drownSfx
        source: resBase + "obj/player/sfx/drown.ogg"
    }

    DWSoundEffect
    {
        id: landSfx
        source: resBase + "obj/player/sfx/land.wav.ogg"
        gain: 0.5
    }

    DWSoundEffect
    {
        id: readySfx
        source: resBase + "obj/player/sfx/ready.wav.ogg"
    }

    onPlayInvicibilityAnimation:
    {
        invincibility.running = true;
    }

    SequentialAnimation
    {
        id: invincibility

        PropertyAnimation
        {
            target: player
            property: "opacity"
            from: 0.25
            to: 0.75
            easing.type: Easing.SineCurve
            duration: convertGenesisTime(12) * 1000
            loops: 10
        }

        ScriptAction
        {
            script:
            {
                player.opacity = 1.0;
                player.playerInvincible = false;
            }
        }
    }

}
