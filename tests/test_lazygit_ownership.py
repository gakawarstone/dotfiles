import subprocess
import tempfile
from pathlib import Path
import unittest


SCRIPT = Path(__file__).resolve().parents[1] / "nix/home/gws/check-lazygit-target.sh"


class LazygitOwnershipTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.config = self.root / "lazygit"

    def check(self):
        return subprocess.run(["bash", str(SCRIPT), str(self.config)], capture_output=True)

    def test_stow_file_and_folded_directory_are_rejected(self):
        checkout = self.root / "checkout"
        checkout.mkdir()
        original = checkout / "config.yml"
        original.write_text("git: {}\n")
        self.config.mkdir()
        (self.config / "config.yml").symlink_to(original)
        self.assertNotEqual(self.check().returncode, 0)
        (self.config / "config.yml").unlink()
        self.config.rmdir()
        self.config.symlink_to(checkout, target_is_directory=True)
        self.assertNotEqual(self.check().returncode, 0)
        self.assertEqual(original.read_text(), "git: {}\n")

    def test_free_and_managed_paths_are_allowed(self):
        self.config.mkdir()
        self.assertEqual(self.check().returncode, 0)
        (self.config / "config.yml").symlink_to(
            "/nix/store/test-home-manager-files/.config/lazygit/config.yml"
        )
        self.assertEqual(self.check().returncode, 0)


if __name__ == "__main__":
    unittest.main()
