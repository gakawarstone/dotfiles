import ".."

AudioControl {
    audioNode: "@DEFAULT_AUDIO_SINK@"
    label: "Volume"
    icon: {
        if (muted || volume === 0) return "󰝟";
        if (volume < 0.33) return "󰕿";
        if (volume < 0.66) return "󰖀";
        return "󰕾";
    }
    accentColor: Theme.blue
    popupMutedIconColor: Theme.overlay0
}
