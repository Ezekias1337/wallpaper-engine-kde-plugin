import QtQuick 2.5
import QtMultimedia 5.13
import ".."

Item{
    id: videoItem
    anchors.fill: parent
    property alias source: player.source
    property int displayMode: background.displayMode
    property var volumeFade: Common.createVolumeFade(
        videoItem, 
        Qt.binding(function() { return background.mute ? 0 : background.volume; }),
        (volume) => { player.volume = volume / 100.0; }
    )

    onDisplayModeChanged: {
        if(displayMode == Common.DisplayMode.Scale)
            videoView.fillMode = VideoOutput.Stretch;
        else if(displayMode == Common.DisplayMode.Aspect)
            videoView.fillMode = VideoOutput.PreserveAspectFit;
        else if(displayMode == Common.DisplayMode.Tile) {
            videoView.fillMode = VideoOutput.PreserveAspectFit;
            tileContent();  // Call the function to tile content
        } else if(displayMode == Common.DisplayMode.Crop)
            videoView.fillMode = VideoOutput.PreserveAspectCrop;
    }

    Grid {
        id: tileGrid
        anchors.fill: parent
        visible: false
        columns: Math.ceil(width / videoView.width)
        rows: Math.ceil(height / videoView.height)

        Repeater {
            model: tileGrid.columns * tileGrid.rows
            delegate: VideoOutput {
                id: videoView
                width: videoItem.width / tileGrid.columns
                height: videoItem.height / tileGrid.rows
                source: player
                flushMode: VideoOutput.LastFrame
                fillMode: VideoOutput.PreserveAspectFit
            }
        }
    }

    VideoOutput {
        id: videoView
        anchors.fill: parent
        source: player
        flushMode: VideoOutput.LastFrame
    }
    
    MediaPlayer {
        id: player
        autoPlay: true
        loops: MediaPlayer.Infinite
        muted: background.mute
        volume: 0.0
        playbackRate: background.videoRate
    }

    Component.onCompleted:{
        background.nowBackend = "QtMultimedia";
        videoItem.displayModeChanged();
    }

    function tileContent() {
        // Make the grid visible for tiling
        tileGrid.visible = true;
    }

    function play(){
        pauseTimer.stop();
        player.play();
        volumeFade.start();
    }

    function pause(){
        volumeFade.stop();
        pauseTimer.start();
    }

    Timer{
        id: pauseTimer
        running: false
        repeat: false
        interval: 300
        onTriggered: {
            player.pause();
        }
    }

    function getMouseTarget() {
    }
}
