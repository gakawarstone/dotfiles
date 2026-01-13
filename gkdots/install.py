import os
import subprocess
from pathlib import Path

from config import INCLUDED_BINS, BIN_FILES_PATH, INCLUDED_CONFIGS
from _types import BinFileLinkingInfo, ConfigDirLinkingInfo


def _run_cmd(cmd: list[str], cwd: Path | None = None, capture_output: bool = False):
    if not cwd:
        cwd = Path(os.getcwd())
    else:
        print(cwd.as_posix(), end=" ")

    try:
        print(*cmd)
        subprocess.run(cmd, cwd=cwd, check=True, capture_output=capture_output)
    except subprocess.CalledProcessError as e:
        print(f"Error running command")
        raise


def _link_bin_file(file_path: Path, target_path: Path):
    if os.path.exists(target_path) or os.path.islink(target_path):
        if target_path.resolve() == file_path.resolve():
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


def _install_config(
    config: ConfigDirLinkingInfo,
    configs_dir: Path = Path("configs/"),
    target_dir: Path = Path.home(),
    adopt: bool = False,
):
    cmd = [
        "stow",
        "-d",
        configs_dir.as_posix(),
        "-t",
        target_dir.as_posix(),
        config.name,
    ]

    if adopt:
        cmd.insert(1, "--adopt")
    try:
        _run_cmd(cmd, capture_output=True)
    except subprocess.CalledProcessError as e:
        if "--adopt" in str(e.stderr):
            print("There is config for", config.name)
            if input("Rewrite it (y/n)") == "y":
                _install_config(config, configs_dir, target_dir, adopt=True)


def install_bins(
    included_files: list[BinFileLinkingInfo] = INCLUDED_BINS,
    path_to_install: Path = BIN_FILES_PATH,
):
    if not os.path.isdir(path_to_install):
        if input(f"Create {path_to_install}:") == "y":
            os.makedirs(path_to_install)

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
        _install_config(config, configs_dir, target_dir)


def install_dwm():
    cmd = ["make", "all"]
    dwm_package_path = Path(os.getcwd()) / "packages" / "dwm"
    _run_cmd(cmd, dwm_package_path)

    dwm_package_bins_path = dwm_package_path / "bin"
    _link_bin_file(dwm_package_bins_path / "dwm", BIN_FILES_PATH / "dwm")
    _link_bin_file(dwm_package_bins_path / "dmenu", BIN_FILES_PATH / "dmenu")
    _link_bin_file(dwm_package_bins_path / "dmenu_run", BIN_FILES_PATH / "dmenu_run")
    _link_bin_file(dwm_package_bins_path / "slstatus", BIN_FILES_PATH / "slstatus")
    _link_bin_file(dwm_package_bins_path / "st", BIN_FILES_PATH / "st")


def install_tmux():
    _install_config(ConfigDirLinkingInfo("tmux"))
    tmux_config_path = Path().home() / ".config" / "tmux"
    cmd = ["make", "all"]
    _run_cmd(cmd, tmux_config_path)


if __name__ == "__main__":
    install_bins()
    install_configs()
    install_tmux()
    install_dwm()
