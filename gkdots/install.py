import os
import subprocess
from pathlib import Path

from config import INCLUDED_BINS, BIN_FILES_PATH, INCLUDED_CONFIGS
from _types import BinFileLinkingInfo, ConfigDirLinkingInfo


def _run_cmd(cmd: list[str]):
    try:
        print(*cmd)
        subprocess.run(cmd, check=True)
    except subprocess.CalledProcessError as e:
        print(f"Error running command: {e}")
        raise


def _link_bin_file(file_path: Path, target_path: Path):
    if os.path.exists(target_path) or os.path.islink(target_path):
        if target_path.resolve() == file_path:
            print(f"Link from {file_path} to {target_path} exist")
            return

        should_relink = input(f"File {target_path} exists \nrelink?: ")
        if should_relink == "y":
            print(f"Deleting {target_path}")
            target_path.unlink()
        else:
            print(f"file {file_path} would not be linked")
            return

    cmd = ["ln", "-s", file_path, target_path]
    _run_cmd(cmd)


def install_bins(
    included_files: list[BinFileLinkingInfo] = INCLUDED_BINS,
    path_to_install: Path = BIN_FILES_PATH,
):
    for file_info in included_files:
        file_path = Path(os.getcwd()) / "bins" / file_info.file_name
        target_path = path_to_install / file_info.target_file_name
        _link_bin_file(file_path, target_path)


def install_configs(
    included_configs: list[ConfigDirLinkingInfo] = INCLUDED_CONFIGS,
    configs_dir: Path = Path("configs/"),
    target_dir=Path.home(),
):
    for config in included_configs:
        cmd = [
            "stow",
            "-d",
            configs_dir.as_posix(),
            "-t",
            target_dir.as_posix(),
            config.name,
        ]
        _run_cmd(cmd)


if __name__ == "__main__":
    install_bins()
    install_configs()
