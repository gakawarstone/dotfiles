import contextlib
import importlib.util
import io
import shutil
import subprocess
import sys
import tempfile
import types
import unittest
from pathlib import Path
from unittest.mock import patch


GKDOTS = Path(__file__).resolve().parents[1] / "gkdots"
sys.path.insert(0, str(GKDOTS))
config_module = types.ModuleType("config")
config_module.INCLUDED_BINS = []
config_module.BIN_FILES_PATH = Path("/unused")
config_module.INCLUDED_CONFIGS = []
with patch.dict(sys.modules, {"config": config_module}):
    spec = importlib.util.spec_from_file_location("gkdots_install", GKDOTS / "install.py")
    install = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(install)


@unittest.skipUnless(shutil.which("stow"), "GNU Stow is required")
class InstallConfigTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        root = Path(self.temp.name)
        self.configs = root / "configs"
        self.home = root / "home"
        self.home.mkdir()
        self.package_file = self.configs / "example" / ".config" / "example" / "settings"
        self.package_file.parent.mkdir(parents=True)
        self.package_file.write_text("repository settings\n")
        self.home_file = self.home / ".config" / "example" / "settings"
        self.config = install.ConfigDirLinkingInfo("example")

    def run_install(self, **kwargs):
        with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
            install._install_config(self.config, self.configs, self.home, **kwargs)

    def test_links_when_no_conflict(self):
        self.run_install()
        self.assertEqual(self.home_file.read_text(), "repository settings\n")
        self.assertTrue(self.home_file.resolve().samefile(self.package_file))

    def test_conflict_preserves_both_files_without_prompt(self):
        self.home_file.parent.mkdir(parents=True)
        self.home_file.write_text("home settings\n")
        stderr = io.StringIO()
        with patch("builtins.input", side_effect=AssertionError("unexpected prompt")):
            with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(stderr):
                with self.assertRaises(subprocess.CalledProcessError):
                    install._install_config(self.config, self.configs, self.home)
        self.assertIn("Resolve the conflict manually", stderr.getvalue())
        self.assertEqual(self.package_file.read_text(), "repository settings\n")
        self.assertEqual(self.home_file.read_text(), "home settings\n")
        self.assertFalse(self.home_file.is_symlink())

    def test_explicit_adopt_remains_available(self):
        self.home_file.parent.mkdir(parents=True)
        self.home_file.write_text("home settings\n")
        self.run_install(adopt=True)
        self.assertEqual(self.package_file.read_text(), "home settings\n")
        self.assertTrue(self.home_file.is_symlink())


if __name__ == "__main__":
    unittest.main()
