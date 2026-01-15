from pathlib import Path

from datatypes import BinFileLinkingInfo, ConfigDirLinkingInfo


BIN_FILES_PATH = Path("~/.local/bin/").expanduser()

# TODO: all posibble configs commented
INCLUDED_BINS = [
    # BinFileLinkingInfo("daily", "daily"),
    # BinFileLinkingInfo("vivaldi.hidpi", "browser"),
    # BinFileLinkingInfo("tg.ignore_qt_scaling", "tg"),
    # BinFileLinkingInfo("screen", "screen"),
    # BinFileLinkingInfo("battery_notify", "battery_notify"),
    # BinFileLinkingInfo("tgsend", "tgsend"),
    # BinFileLinkingInfo("wal", "wal"),
    # BinFileLinkingInfo("autocommit", "autocommit"),
]

INCLUDED_CONFIGS = [
    ConfigDirLinkingInfo("tmux"),
    ConfigDirLinkingInfo("alacritty"),
    ConfigDirLinkingInfo("bat"),
    # ConfigDirLinkingInfo("dunst"),
    # ConfigDirLinkingInfo("wal"),
    ConfigDirLinkingInfo("fish"),
    # ConfigDirLinkingInfo("yazi"),
]
