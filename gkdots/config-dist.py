from pathlib import Path

from _types import BinFileLinkingInfo


BIN_FILES_PATH = Path("~/.local/bin/").expanduser()

# files in bins directory to install in BIN_FILES_PATH
# (name_in_bins_dir, target_executable_name)
# ("tg.hidpi", "tg")
INCLUDED_BINS = [
    BinFileLinkingInfo("call_mode", "call_mode"),
    BinFileLinkingInfo("daily", "daily"),
    BinFileLinkingInfo("screen", "screen"),
    BinFileLinkingInfo("tg.ignore_qt_scaling", "tg"),
    BinFileLinkingInfo("tt", "tt"),
    BinFileLinkingInfo("vivaldi.hidpi", "browser"),
    BinFileLinkingInfo("webcam", "webcam"),
]
