import os
from pathlib import Path
import subprocess
import tempfile
import unittest


SCRIPT = Path(__file__).resolve().parents[1] / "bins/screen"


class ScreenTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.home = Path(self.tmp.name)
        (self.home / "Images").mkdir()
        self.bin = self.home / "bin"
        self.bin.mkdir()
        self.env = dict(os.environ, HOME=str(self.home), XDG_SESSION_TYPE="wayland",
                        PATH=f"{self.bin}:/usr/bin:/bin", TEST_HOME=str(self.home))
        self.command("slurp", 'printf "10,20 100x80\\n"')
        self.command("grim", 'printf "%s\\n" "$*" > "$TEST_HOME/grim-args"; printf new > "${@: -1}"')
        self.command("wl-copy", 'cat > "$TEST_HOME/clipboard"')

    def command(self, name, body):
        path = self.bin / name
        path.write_text("#!/bin/bash\n" + body + "\n")
        path.chmod(0o755)

    def run_screen(self, mode):
        return subprocess.run(["bash", str(SCRIPT), mode], env=self.env, capture_output=True)

    def test_success_copies_new_screenshot(self):
        self.assertEqual(self.run_screen("area").returncode, 0)
        self.assertEqual((self.home / "clipboard").read_text(), "new")
        self.assertIn("-g 11,21 98x78", (self.home / "grim-args").read_text())

    def test_cancellation_and_capture_failure_do_not_copy_old_screenshot(self):
        (self.home / "Images/screenshot.png").write_text("old")
        self.command("slurp", "exit 1")
        self.assertNotEqual(self.run_screen("area").returncode, 0)
        self.assertFalse((self.home / "clipboard").exists())
        self.command("grim", "exit 1")
        self.assertNotEqual(self.run_screen("root").returncode, 0)
        self.assertFalse((self.home / "clipboard").exists())

    def test_x11_failure_does_not_copy_old_screenshot(self):
        self.env.update(XDG_SESSION_TYPE="x11", WAYLAND_DISPLAY="")
        self.command("xwd", "exit 1")
        self.command("xclip", 'cat > "$TEST_HOME/clipboard"')
        (self.home / "Images/screenshot.jpg").write_text("old")
        self.assertNotEqual(self.run_screen("root").returncode, 0)
        self.assertFalse((self.home / "clipboard").exists())

    def test_x11_success_copies_new_screenshot(self):
        self.env.update(XDG_SESSION_TYPE="x11", WAYLAND_DISPLAY="")
        self.command("xwd", 'printf source > "${@: -1}"')
        self.command("convert", 'printf new > "$2"')
        self.command("xclip", 'cat > "$TEST_HOME/clipboard"')
        self.assertEqual(self.run_screen("root").returncode, 0)
        self.assertEqual((self.home / "clipboard").read_text(), "new")

    def test_invalid_mode_fails(self):
        self.assertNotEqual(self.run_screen("other").returncode, 0)
        self.assertFalse((self.home / "clipboard").exists())


if __name__ == "__main__":
    unittest.main()
