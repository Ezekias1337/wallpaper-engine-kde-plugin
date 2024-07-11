import QtQuick 2.5
import com.github.catsout.wallpaperEngineKde 1.2
import ".."

Item {
    id: sceneItem
    anchors.fill: parent
    property alias source: player.source
    property string assets: "assets"
    property int displayMode: background.displayMode
    property var volumeFade: Common.createVolumeFade(
        sceneItem, 
        Qt.binding(function() { return background.mute ? 0 : background.volume; }),
        (volume) => { player.volume = volume / 100.0; }
    )

    onDisplayModeChanged: {
        if (displayMode == Common.DisplayMode.Scale) {
            player.fillMode = SceneViewer.STRETCH;
        } else if (displayMode == Common.DisplayMode.Aspect) {
            player.fillMode = SceneViewer.ASPECTFIT;
        } else if (displayMode == Common.DisplayMode.Crop) {
            player.fillMode = SceneViewer.ASPECTCROP;
        } else if (displayMode == Common.DisplayMode.Tile) {
            player.fillMode = SceneViewer.TILE;
            tileContent();
        }
    }

    SceneViewer {
        id: player
        anchors.fill: parent
        fps: background.fps
        muted: background.mute
        speed: background.speed
        assets: sceneItem.assets
        fillMode: Image.PreserveAspectFit  // Default to preserve aspect ratio
        source: player.source
        
        Component.onCompleted: {
            player.setAcceptMouse(true);
            player.setAcceptHover(true);
        }

        Connections {
            ignoreUnknownSignals: true
            onFirstFrame: {
                background.sig_backendFirstFrame('scene');
            }
        }
    }

    Component.onCompleted: {
        background.nowBackend = 'scene';
        sceneItem.displayModeChanged();
    }
    
    function tileContent() {
        var screenWidth = player.width;
        var screenHeight = player.height;
        var imageWidth = player.sourceSize.width;
        var imageHeight = player.sourceSize.height;

        if (imageWidth < 1920 && imageHeight < 1080) {
            player.repeatMode = Image.TileHorizontally;  // Tile horizontally
        } else {
            player.repeatMode = Image.Stretch;  // Default to stretch if no tiling needed
        }
    }
    
    function play() {
        volumeFade.start();
        player.play();
    }
    
    function pause() {
        volumeFade.stop();
        player.pause();
    }
    
    function getMouseTarget() {
        return Qt.binding(function() { return player; })
    }
}
