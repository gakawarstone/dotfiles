import ".."

AudioControl {
    audioNode: "@DEFAULT_AUDIO_SOURCE@"
    label: "Microphone"
    icon: muted ? "󰍭" : "󰍬"
    accentColor: Theme.peach
}
