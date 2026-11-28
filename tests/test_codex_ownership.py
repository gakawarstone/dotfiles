import subprocess
import tempfile
from pathlib import Path
import unittest

SCRIPT = Path(__file__).resolve().parents[1] / "nix/home/gws/check-codex-instructions-target.sh"


class CodexOwnershipTests(unittest.TestCase):
    def test_target_ownership(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            directory = root / ".codex"
            run = lambda: subprocess.run(["bash", str(SCRIPT), str(directory)], capture_output=True).returncode
            self.assertEqual(run(), 0)
            directory.mkdir()
            target = directory / "AGENTS.md"
            target.write_text("local instructions\n")
            self.assertNotEqual(run(), 0)
            self.assertEqual(target.read_text(), "local instructions\n")
            target.unlink()
            target.symlink_to("/nix/store/test-home-manager-files/.codex/AGENTS.md")
            self.assertEqual(run(), 0)
            target.unlink()
            directory.rmdir()
            directory.symlink_to(root / "elsewhere", target_is_directory=True)
            self.assertNotEqual(run(), 0)


if __name__ == "__main__":
    unittest.main()
