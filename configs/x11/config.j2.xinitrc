slstatus &
picom &
setxkbmap -layout us,de,ru -option grp:alt_shift_toggle

wal -i {{wallpaper_path}}

{% if mount_cloud == "true" %}
rclone mount pcloud: /home/gws/cloud --vfs-cache-mode full &
{% endif %}

{% if hidpi == "true" %}
export QT_AUTO_SCREEN_SCALE_FACTOR=0
export QT_SCALE_FACTOR=1.5
{% endif %}

{% if twmnd == "true" %}
twmnd &
{% endif %}

{% if xbindkeys == "true" %}
xbindkeys
{% endif %}

exec dwm
