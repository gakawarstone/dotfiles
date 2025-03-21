from pathlib import Path

from _types import BinFileLinkingInfo, ConfigDirLinkingInfo


BIN_FILES_PATH = Path("~/.local/bin/").expanduser()

INCLUDED_BINS = [
    BinFileLinkingInfo("daily", "daily"),
    BinFileLinkingInfo("screen", "screen"),
]

INCLUDED_CONFIGS = [
    ConfigDirLinkingInfo("nvim-mini"),
    ConfigDirLinkingInfo("tmux"),
    ConfigDirLinkingInfo("alacritty"),
    ConfigDirLinkingInfo("dunst"),
    ConfigDirLinkingInfo("ranger"),
    ConfigDirLinkingInfo("wal"),
]
