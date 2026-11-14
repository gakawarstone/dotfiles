import subprocess
import tempfile
from pathlib import Path
import unittest


SCRIPT = Path(__file__).resolve().parents[1] / "nix/home/gws/check-bat-target.sh"


class BatOwnershipTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.bat = self.root / "bat"

    def check(self):
        return subprocess.run(["bash", str(SCRIPT), str(self.bat)], capture_output=True)

    def test_rejects_folded_stow_directory_even_with_identical_file(self):
        original = self.root / "checkout"
        original.mkdir()
        (original / "config").write_text('--theme="Catppuccin Mocha"\n')
        self.bat.symlink_to(original, target_is_directory=True)
        self.assertNotEqual(self.check().returncode, 0)
        self.assertEqual((original / "config").read_text(), '--theme="Catppuccin Mocha"\n')

    def test_rejects_unmanaged_config(self):
        self.bat.mkdir()
        (self.bat / "config").write_text("local config\n")
        self.assertNotEqual(self.check().returncode, 0)
        self.assertEqual((self.bat / "config").read_text(), "local config\n")

    def test_allows_free_or_managed_target(self):
        self.bat.mkdir()
        self.assertEqual(self.check().returncode, 0)
        (self.bat / "config").symlink_to("/nix/store/test-home-manager-files/.config/bat/config")
        self.assertEqual(self.check().returncode, 0)


if __name__ == "__main__":
    unittest.main()
