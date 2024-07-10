import QtQuick 2.5
import com.github.catsout.wallpaperEngineKde 1.2
import ".."

Item {
    id: root
    width: 1920
    height: 1080

    property alias displayMode: displayMode

    Image {
        id: mainImage
        source: "path/to/your/image"
        anchors.centerIn: parent
    }

    Repeater {
        id: backgroundRepeater
        model: 2 // Left and right copies
        delegate: Image {
            source: mainImage.source
            x: mainImage.x + (index == 0 ? -mainImage.width : mainImage.width)
            y: mainImage.y
        }
    }

    function tileBackgroundImage() {
        // Ensure mainImage is centered
        mainImage.anchors.centerIn = parent

        // Remove any existing repeated images
        backgroundRepeater.model = 0

        // Add left and right copies
        backgroundRepeater.model = 2
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
