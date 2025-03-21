from typing import NamedTuple


class BinFileLinkingInfo(NamedTuple):
    file_name: str
    target_file_name: str


class ConfigDirLinkingInfo(NamedTuple):
    name: str
