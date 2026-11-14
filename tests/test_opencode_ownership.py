import subprocess
import tempfile
from pathlib import Path
import unittest


SCRIPT = Path(__file__).resolve().parents[1] / "nix/home/gws/check-opencode-targets.sh"


class OpenCodeOwnershipTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.config = self.root / "opencode"

    def check(self):
        return subprocess.run(["bash", str(SCRIPT), str(self.config)], capture_output=True)

    def test_folded_directories_are_rejected(self):
        checkout = self.root / "checkout"
        checkout.mkdir()
        self.config.symlink_to(checkout, target_is_directory=True)
        self.assertNotEqual(self.check().returncode, 0)
        self.config.unlink()
        self.config.mkdir()
        (self.config / "plugins").symlink_to(checkout, target_is_directory=True)
        self.assertNotEqual(self.check().returncode, 0)

    def test_unmanaged_file_is_preserved(self):
        (self.config / "plugins").mkdir(parents=True)
        original = self.config / "plugins/wakatime.js"
        original.write_text("local plugin\n")
        self.assertNotEqual(self.check().returncode, 0)
        self.assertEqual(original.read_text(), "local plugin\n")

    def test_managed_paths_and_unrelated_files_are_allowed(self):
        (self.config / "plugins").mkdir(parents=True)
        local = self.config / "plugins/other-local-plugin.js"
        local.write_text("preserve me\n")
        for name in ("opencode.json", "plugins/herdr-agent.js", "plugins/herdr-pane-title.js", "plugins/wakatime.js"):
            (self.config / name).symlink_to(f"/nix/store/test-home-manager-files/.config/opencode/{name}")
        self.assertEqual(self.check().returncode, 0)
        self.assertEqual(local.read_text(), "preserve me\n")


if __name__ == "__main__":
    unittest.main()
