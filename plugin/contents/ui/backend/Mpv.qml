import QtQuick 2.5
import com.github.catsout.wallpaperEngineKde 1.2
import ".."

Item {
    id: root
    width: 1920
    height: 1080

    property int displayMode: background.displayMode

    Image {
        id: mainImage
        source: background.source // Use the dynamic source from main.qml
        anchors.centerIn: parent
        visible: false // Hide the main image itself
    }

    Grid {
        id: tileGrid
        anchors.fill: parent
        visible: false // Make visible only when tiling
    }

    function tileBackgroundImage() {
        // Ensure mainImage is centered
        mainImage.anchors.centerIn = parent

        // Calculate the number of tiles needed
        var columns = Math.ceil(root.width / mainImage.width);
        var rows = Math.ceil(root.height / mainImage.height);
        var totalTiles = columns * rows;

        // Update the repeater model
        tileGrid.visible = true
        tileGrid.columns = columns;
        tileGrid.rows = rows;

        tileRepeater.model = totalTiles;
    }

    Repeater {
        id: tileRepeater
        delegate: Image {
            source: mainImage.source
            width: mainImage.width
            height: mainImage.height
        }
    }
}

Item {
    id: videoItem
    anchors.fill: parent
    property alias source: player.source
    readonly property int displayMode: background.displayMode
    readonly property real videoRate: background.speed
    readonly property bool stats: background.mpvStats
    property var volumeFade: Common.createVolumeFade(
        videoItem, 
        Qt.binding(function() { return background.mute ? 0 : background.volume; }),
        function(volume) { player.volume = volume; }
    )

    onDisplayModeChanged: {
        if (videoItem.displayMode == Common.DisplayMode.Crop) {
            player.setProperty("keepaspect", true);
            player.setProperty("panscan", 1.0);
        } else if (videoItem.displayMode == Common.DisplayMode.Aspect) {
            player.setProperty("keepaspect", true);
            player.setProperty("panscan", 0.0);
        } else if (videoItem.displayMode == Common.DisplayMode.Scale) {
            player.setProperty("keepaspect", false);
            player.setProperty("panscan", 0.0);
        } else if (videoItem.displayMode == Common.DisplayMode.Tile) {
            player.setProperty("keepaspect", true);
            player.setProperty("panscan", 0.0);
            root.tileBackgroundImage();
        }
    }

    onStatsChanged: {
        player.command(["script-binding", "stats/display-stats-toggle"]);
    }

    onVideoRateChanged: player.setProperty('speed', videoRate);

    Mpv {
        id: player
        anchors.fill: parent
        mute: background.mute
        volume: 0
        Connections {
            ignoreUnknownSignals: true
            onFirstFrame: {
                background.sig_backendFirstFrame('mpv');
            }
        }
    }

    Component.onCompleted: {
        background.nowBackend = 'mpv';
        videoItem.displayModeChanged();
    }

    function play() {
        pauseTimer.stop();
        player.play();
        volumeFade.start();
    }

    function pause() {
        volumeFade.stop();
        pauseTimer.start();
    }

    Timer {
        id: pauseTimer
        running: false
        repeat: false
        interval: 200
        onTriggered: {
            player.pause();
        }
    }

    function getMouseTarget() {}
}
