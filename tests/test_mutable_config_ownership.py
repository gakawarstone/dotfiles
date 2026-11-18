"""Protect existing mutable configs when Home Manager takes ownership."""
from pathlib import Path
import subprocess
import tempfile
import unittest

SCRIPTS = Path(__file__).resolve().parents[1] / "nix/home/gws"
CONFIGS = (
    ("foot", ("foot.ini", "theme.ini")),
    ("hypr", ("hyprland.lua",)),
    ("quickshell", ("shell.qml",)),
)


class MutableDirectoryOwnershipTests(unittest.TestCase):
    def test_existing_checkout_is_preserved_and_managed_link_allowed(self):
        for name, files in CONFIGS:
            with self.subTest(name=name), tempfile.TemporaryDirectory() as tmp:
                root = Path(tmp)
                source = root / "checkout"
                source.mkdir()
                for file in files:
                    (source / file).write_text("local content\n")
                target = root / name
                script = SCRIPTS / f"check-{'hyprland' if name == 'hypr' else name}-target.sh"

                def check():
                    return subprocess.run(["bash", str(script), str(target), str(source)], capture_output=True).returncode

                self.assertEqual(check(), 0)
                target.symlink_to(source, target_is_directory=True)
                self.assertNotEqual(check(), 0)
                self.assertEqual((source / files[0]).read_text(), "local content\n")
                target.unlink()
                target.mkdir()
                self.assertNotEqual(check(), 0)
                target.rmdir()
                target.symlink_to(f"/nix/store/test-home-manager-files/.config/{name}")
                self.assertEqual(check(), 0)
                (source / files[-1]).unlink()
                self.assertNotEqual(check(), 0)


class MimeappsOwnershipTests(unittest.TestCase):
    def test_preserves_existing_settings_and_accepts_managed_link(self):
        with tempfile.TemporaryDirectory() as tmp:
            target = Path(tmp) / "mimeapps.list"
            script = SCRIPTS / "check-mimeapps-target.sh"
            def check():
                return subprocess.run(["bash", str(script), str(target)], capture_output=True).returncode
            self.assertEqual(check(), 0)
            target.write_text("local settings")
            self.assertNotEqual(check(), 0)
            self.assertEqual(target.read_text(), "local settings")
            target.unlink()
            target.symlink_to("/nix/store/test-home-manager-files/.config/mimeapps.list")
            self.assertEqual(check(), 0)


class GtkOwnershipTests(unittest.TestCase):
    def test_preserves_local_files_and_accepts_managed_links(self):
        for version, names in (("3", ("gtk.css",)), ("4", ("gtk.css", "gtk-dark.css"))):
            with self.subTest(version=version), tempfile.TemporaryDirectory() as tmp:
                root = Path(tmp)
                directory = root / f"gtk-{version}.0"
                directory.mkdir()
                script = SCRIPTS / ("check-gtk3-target.sh" if version == "3" else "check-gtk4-targets.sh")
                def check():
                    return subprocess.run(["bash", str(script), str(directory)], capture_output=True).returncode
                self.assertEqual(check(), 0)
                for name in names:
                    target = directory / name
                    target.write_text("local CSS")
                    self.assertNotEqual(check(), 0)
                    self.assertEqual(target.read_text(), "local CSS")
                    target.unlink()
                    target.symlink_to(f"/nix/store/test-home-manager-files/.config/gtk-{version}.0/{name}")
                self.assertEqual(check(), 0)
                for name in names:
                    (directory / name).unlink()
                directory.rmdir()
                directory.symlink_to(root, target_is_directory=True)
                self.assertNotEqual(check(), 0)


class HerdrOwnershipTests(unittest.TestCase):
    def test_runtime_files_and_unmanaged_config_are_preserved(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            directory = root / "herdr"
            directory.mkdir()
            source = root / "source.toml"
            source.write_text("setting = true\n")
            runtime = directory / "session.json"
            runtime.write_text("session data\n")
            target = directory / "config.toml"
            script = SCRIPTS / "check-herdr-target.sh"

            def check():
                return subprocess.run(["bash", str(script), str(directory), str(source)], capture_output=True).returncode

            self.assertEqual(check(), 0)
            target.symlink_to(source)
            self.assertNotEqual(check(), 0)
            target.unlink()
            target.symlink_to("/nix/store/test-home-manager-files/.config/herdr/config.toml")
            self.assertEqual(check(), 0)
            self.assertEqual(runtime.read_text(), "session data\n")
            source.unlink()
            self.assertNotEqual(check(), 0)
            self.assertEqual(runtime.read_text(), "session data\n")


if __name__ == "__main__":
    unittest.main()
