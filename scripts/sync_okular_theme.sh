#!/bin/sh

# Okular stores its window scheme separately from its document colors.
command -v kwriteconfig6 >/dev/null 2>&1 || exit 0

case "$1" in
    mocha)
        scheme=CatppuccinMochaMauve
        foreground='#cdd6f4'
        background='#1e1e2e'
        surround='#11111b'
        ;;
    latte)
        scheme=CatppuccinLatteMauve
        foreground='#4c4f69'
        background='#eff1f5'
        surround='#dce0e8'
        ;;
    *)
        echo "Usage: $0 mocha|latte" >&2
        exit 2
        ;;
esac

kwriteconfig6 --file okularrc --group UiSettings --key ColorScheme "$scheme"
kwriteconfig6 --file okularpartrc --group Document --key ChangeColors true
kwriteconfig6 --file okularpartrc --group Document --key RenderMode Recolor
kwriteconfig6 --file okularpartrc --group 'Dlg Accessibility' --key RecolorForeground "$foreground"
kwriteconfig6 --file okularpartrc --group 'Dlg Accessibility' --key RecolorBackground "$background"
kwriteconfig6 --file okularpartrc --group PageView --key UseCustomBackgroundColor true
kwriteconfig6 --file okularpartrc --group PageView --key BackgroundColor "$surround"
