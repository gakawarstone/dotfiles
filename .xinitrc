# Bind keymaps from ~/.xbindkeysrc
xbindkeys

# start notification daemon
twmnd &

# start picom compositor
picom -b

# set hidpi settings for QT apps
export QT_AUTO_SCREEN_SCALE_FACTOR=0
export QT_SCALE_FACTOR=1.5

# set wallpaper
# feh --bg-scale $HOME/Downloads/bg.jpg
feh --bg-scale $HOME/.config/wallpapers/bg.jpg

# start dwm from ~/.local/bin/dwm
exec dwm
