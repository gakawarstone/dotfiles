"""Check Zen profile ownership without opening or changing a browser profile."""
from pathlib import Path
import os
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
GUARD = ROOT / 'nix/home/gws/check-zen-targets.sh'


class ZenOwnershipTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.home = Path(self.tmp.name)
        self.profile = 'test profile (release)'
        self.zen = self.home / '.zen'
        self.directory = self.zen / self.profile
        (self.directory / 'chrome').mkdir(parents=True)
        (self.zen / 'profiles.ini').write_text('[InstallTest]\nDefault=' + self.profile + '\n')
        self.source = self.home / 'dotfiles/configs/zen'
        self.source.mkdir(parents=True)
        (self.source / 'user.js').write_text('user preference\n')
        (self.source / 'userChrome.css').write_text('/* style */\n')
        self.awk = shutil.which('awk')
        self.assertIsNotNone(self.awk)

    def check(self):
        return subprocess.run(['bash', str(GUARD), str(self.home), self.profile, self.awk],
                              capture_output=True).returncode

    def test_preserves_unmanaged_profile_files(self):
        self.assertEqual(self.check(), 0)
        target = self.directory / 'user.js'
        target.write_text('local settings\n')
        self.assertNotEqual(self.check(), 0)
        self.assertEqual(target.read_text(), 'local settings\n')
        target.unlink()
        target.symlink_to(self.source / 'user.js')
        self.assertNotEqual(self.check(), 0)
        self.assertEqual((self.source / 'user.js').read_text(), 'user preference\n')

    def test_allows_managed_targets_and_rejects_changed_profile(self):
        for rel in ('user.js', 'chrome/userChrome.css'):
            (self.directory / rel).symlink_to(
                '/nix/store/test-home-manager-files/.zen/' + self.profile + '/' + rel)
        self.assertEqual(self.check(), 0)
        (self.zen / 'profiles.ini').write_text('[InstallTest]\nDefault=another\n')
        self.assertNotEqual(self.check(), 0)

    def test_rejects_linked_chrome_and_missing_source(self):
        (self.directory / 'chrome').rmdir()
        (self.directory / 'chrome').symlink_to(self.source, target_is_directory=True)
        self.assertNotEqual(self.check(), 0)
        (self.directory / 'chrome').unlink()
        (self.directory / 'chrome').mkdir()
        (self.source / 'user.js').unlink()
        self.assertNotEqual(self.check(), 0)


if __name__ == '__main__':
    unittest.main()
