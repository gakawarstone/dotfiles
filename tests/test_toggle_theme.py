import os
from pathlib import Path
import subprocess
import tempfile
import unittest


SCRIPT = Path(__file__).resolve().parents[1] / "bins/toggle_theme"


class ToggleThemeTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        home = Path(self.tmp.name)
        repo = home / "dotfiles"
        self.hypr = repo / "configs/hyprland/.config/hypr"
        self.foot = repo / "configs/foot/.config/foot"
        self.shell = repo / "configs/quickshell/.config/quickshell"
        for directory in (self.hypr, self.foot, self.shell, repo / "scripts", home / "bin"):
            directory.mkdir(parents=True)
        for directory, name in ((self.hypr, "theme.conf"), (self.hypr, "hyprpaper.conf"),
                                (self.foot, "theme.ini"), (self.shell, "Theme.qml")):
            (directory / name).symlink_to("mocha.conf")
        for name in ("gdbus", "gsettings", "pgrep"):
            self.command(home / "bin" / name, "exit 1")
        self.command(home / "bin/hyprctl", "exit 0")
        self.command(repo / "scripts/sync_okular_theme.sh", "exit 0")
        self.env = dict(os.environ, HOME=str(home), PATH=f"{home}/bin:/usr/bin:/bin")
        self.bin = home / "bin"

    @staticmethod
    def command(path, content):
        path.write_text("#!/bin/sh\n" + content + "\n")
        path.chmod(0o755)

    def run_toggle(self):
        return subprocess.run(["bash", str(SCRIPT)], env=self.env, capture_output=True)

    def test_switches_symlinks(self):
        self.assertEqual(self.run_toggle().returncode, 0)
        self.assertEqual(os.readlink(self.hypr / "theme.conf"), "latte.conf")
        self.assertEqual(os.readlink(self.foot / "theme.ini"), "latte.ini")
        self.assertEqual(os.readlink(self.shell / "Theme.qml"), "Latte.qml")

    def test_preserves_regular_file_without_changing_other_links(self):
        target = self.foot / "theme.ini"
        target.unlink()
        target.write_text("local theme")
        self.assertNotEqual(self.run_toggle().returncode, 0)
        self.assertEqual(target.read_text(), "local theme")
        self.assertEqual(os.readlink(self.hypr / "theme.conf"), "mocha.conf")

    def test_link_failure_stops_switching(self):
        self.command(self.bin / "ln", "exit 1")
        self.assertNotEqual(self.run_toggle().returncode, 0)
        self.assertEqual(os.readlink(self.hypr / "theme.conf"), "mocha.conf")
        self.assertEqual(os.readlink(self.foot / "theme.ini"), "mocha.conf")


if __name__ == "__main__":
    unittest.main()
