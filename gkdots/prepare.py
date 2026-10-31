import subprocess
from pathlib import Path


def build_if_missing(config_dir: Path, output: str):
    path = config_dir / output
    if not path.exists() and not path.is_symlink():
        subprocess.run(["make", "build"], cwd=config_dir, check=True)


def prepare_alacritty(package_dir: Path):
    build_if_missing(package_dir / ".config/alacritty", "alacritty.toml")


def prepare_foot(package_dir: Path):
    config_dir = package_dir / ".config/foot"
    build_if_missing(config_dir, "foot.ini")
    theme = config_dir / "theme.ini"
    if not theme.exists() and not theme.is_symlink():
        theme.symlink_to("mocha.ini")
