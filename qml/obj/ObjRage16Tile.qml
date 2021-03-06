import QtQuick 2.4
import dw 1.0
import ".."

DWFieldObject {
    id: tile
    z: options.tileFile.indexOf("bg-b-") !== -1? field.layerBZ : field.layerAZ
    property var options: null
    property bool sizeMatters: true
    property bool background: options.background? true : false

    DWImageItem {
        id: tileImage
        source: resBase + levelData.urlPrefix + "tileset/" + options.tileFile
        anchors.fill: parent
    }

    DWFOPhysicsBody {
        id: body
        active: tile.active
        bodyType: DWFOPhysicsBody.BT_STATIC
        shapeType: DWFOPhysicsBody.ST_POLY_BOX
        shapeCategory: DWFieldPhysicsWorld.CC_LAYER_A
        shapeCollisionMask: 0xffff
        shapeData: Qt.vector4d(tile.width/2, tile.height/2, 0, 0)
        origin: Qt.point(tile.width/2, tile.height/2)
    }

    function morph()
    {
        if(!background)
            body.rebuildBody();
    }

    /*
    function update()
    {
    }

    Component.onCompleted: {
        objManager.updateObjects.connect(update);
    }
    onActivated: objManager.updateObjects.connect(update);
    onDeactivated: objManager.updateObjects.disconnect(update);
    Component.onDestruction: objManager.updateObjects.disconnect(update);
    */
}

