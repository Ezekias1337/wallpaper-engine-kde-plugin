rm -rf build

plasmapkg2 -r ~/.local/share/plasma/wallpapers/com.github.casout.wallpaperEngineKde

systemctl --user restart plasma-plasmashell.service
