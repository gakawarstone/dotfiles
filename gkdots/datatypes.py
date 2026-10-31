from pathlib import Path
from typing import Callable, NamedTuple


class BinFileLinkingInfo(NamedTuple):
    file_name: str
    target_file_name: str


class ConfigDirLinkingInfo(NamedTuple):
    name: str
    prepare: Callable[[Path], None] | None = None
