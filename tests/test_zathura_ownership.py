import subprocess
import tempfile
from pathlib import Path
import unittest


SCRIPT = Path(__file__).resolve().parents[1] / "nix/home/gws/check-zathura-target.sh"


class ZathuraOwnershipTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.config = self.root / "zathura"

    def check(self):
        return subprocess.run(["bash", str(SCRIPT), str(self.config)], capture_output=True)

    def test_rejects_folded_stow_directory_and_unmanaged_file(self):
        checkout = self.root / "checkout"
        checkout.mkdir()
        original = checkout / "zathurarc"
        original.write_text("set selection-clipboard clipboard\n")
        self.config.symlink_to(checkout, target_is_directory=True)
        self.assertNotEqual(self.check().returncode, 0)
        self.config.unlink()
        self.config.mkdir()
        (self.config / "zathurarc").write_text("local configuration\n")
        self.assertNotEqual(self.check().returncode, 0)
        self.assertEqual(original.read_text(), "set selection-clipboard clipboard\n")

    def test_free_and_managed_paths_are_allowed(self):
        self.config.mkdir()
        self.assertEqual(self.check().returncode, 0)
        (self.config / "zathurarc").symlink_to(
            "/nix/store/test-home-manager-files/.config/zathura/zathurarc"
        )
        self.assertEqual(self.check().returncode, 0)


if __name__ == "__main__":
    unittest.main()
