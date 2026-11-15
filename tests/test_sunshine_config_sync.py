"""Verify declarative Sunshine settings without touching a running service."""
from pathlib import Path
import os
import subprocess
import tempfile
import unittest

SCRIPT = Path(__file__).resolve().parents[1] / 'nix/home/gws/sync-sunshine-config.sh'
TEMPLATE_GUARD = SCRIPT.with_name('check-sunshine-templates.sh')


class SunshineSyncTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.config = self.root / 'config'
        self.config.mkdir()
        self.desired = self.root / 'desired'
        self.desired.mkdir()
        self.previous = self.root / 'previous'
        self.previous.mkdir()
        for name in ('sunshine.conf', 'apps.json'):
            (self.desired / name).write_text('new ' + name)
            (self.previous / name).write_text('old ' + name)
        self.systemctl = self.root / 'systemctl'
        self.set_status('inactive')
        self.private = self.config / 'credentials'
        self.private.mkdir()
        (self.private / 'key.pem').write_text('private data')

    def set_status(self, status):
        self.systemctl.write_text('#!/bin/sh\nprintf "%s\\n" "$*" >> "$STATUS_LOG"\nprintf "' + status + '\\n"\n')
        self.systemctl.chmod(0o755)

    def run_sync(self, mode, device='iphone'):
        return subprocess.run(['bash', str(SCRIPT), mode, device, str(self.config),
                               str(self.desired / 'sunshine.conf'), str(self.desired / 'apps.json'),
                               str(self.previous), str(self.systemctl)], capture_output=True,
                              env=dict(os.environ, STATUS_LOG=str(self.root / 'calls')))

    def test_identical_files_are_left_untouched_even_if_running(self):
        for name in ('sunshine.conf', 'apps.json'):
            (self.config / name).write_bytes((self.desired / name).read_bytes())
        before = (self.config / 'sunshine.conf').stat().st_ino
        self.set_status('active')
        self.assertEqual(self.run_sync('apply').returncode, 0)
        self.assertEqual((self.config / 'sunshine.conf').stat().st_ino, before)
        self.assertEqual((self.private / 'key.pem').read_text(), 'private data')

    def test_updates_previous_managed_files_only_when_stopped(self):
        for name in ('sunshine.conf', 'apps.json'):
            (self.config / name).write_bytes((self.previous / name).read_bytes())
        self.set_status('active')
        self.assertNotEqual(self.run_sync('apply').returncode, 0)
        self.assertEqual((self.config / 'apps.json').read_text(), 'old apps.json')
        self.set_status('inactive')
        self.assertEqual(self.run_sync('apply').returncode, 0)
        for name in ('sunshine.conf', 'apps.json'):
            self.assertEqual((self.config / name).read_bytes(), (self.desired / name).read_bytes())
            self.assertEqual((self.config / name).stat().st_mode & 0o777, 0o600)
        self.assertEqual((self.private / 'key.pem').read_text(), 'private data')

    def test_rejects_unmanaged_changes_and_symlinks(self):
        target = self.config / 'sunshine.conf'
        target.write_text('custom local settings')
        self.assertNotEqual(self.run_sync('apply').returncode, 0)
        self.assertEqual(target.read_text(), 'custom local settings')
        target.unlink()
        target.symlink_to(self.desired / 'sunshine.conf')
        self.assertNotEqual(self.run_sync('apply').returncode, 0)
        self.assertTrue(target.is_symlink())

    def test_does_not_update_if_service_status_is_unknown(self):
        self.set_status('unknown')
        self.assertNotEqual(self.run_sync('apply').returncode, 0)
        self.assertFalse((self.config / 'sunshine.conf').exists())

    def test_running_ipad_blocks_updates_without_touching_files(self):
        for name in ('sunshine.conf', 'apps.json'):
            (self.config / name).write_bytes((self.previous / name).read_bytes())
        self.set_status('active')
        self.assertNotEqual(self.run_sync('apply', 'ipad').returncode, 0)
        self.assertEqual((self.config / 'sunshine.conf').read_text(), 'old sunshine.conf')
        self.assertIn('is-active ipad-screen.service', (self.root / 'calls').read_text())

    def test_running_ipad_with_identical_settings_needs_no_write(self):
        for name in ('sunshine.conf', 'apps.json'):
            (self.config / name).write_bytes((self.desired / name).read_bytes())
        before = (self.config / 'sunshine.conf').stat().st_ino
        self.set_status('active')
        self.assertEqual(self.run_sync('apply', 'ipad').returncode, 0)
        self.assertEqual((self.config / 'sunshine.conf').stat().st_ino, before)
        self.assertFalse((self.root / 'calls').exists())

    def test_invalid_device_is_rejected(self):
        self.assertNotEqual(self.run_sync('apply', 'other').returncode, 0)
        self.assertFalse((self.config / 'sunshine.conf').exists())

    def test_existing_installer_preserves_regular_managed_files(self):
        for device in ('iphone', 'ipad'):
            home = self.root / ('home-' + device)
            config = home / ('.config/sunshine-' + device)
            config.mkdir(parents=True)
            for name in ('sunshine.conf', 'apps.json'):
                (config / name).write_bytes((self.desired / name).read_bytes())
            credentials = config / 'credentials'
            credentials.mkdir()
            (credentials / 'cakey.pem').write_text('private data')
            hypr = home / '.config/hypr'
            hypr.mkdir()
            (hypr / (device + '.lua')).write_text('-- test')
            env = dict(os.environ, HOME=str(home), XDG_CONFIG_HOME=str(home / '.config'),
                       MOBILE_SCREEN_DEVICE=device)
            installer = SCRIPT.parents[3] / 'scripts/install_ipad_screen.sh'
            for _ in range(2):
                subprocess.run(['bash', str(installer), '--configure-only'], env=env,
                               check=True, capture_output=True)
            for name in ('sunshine.conf', 'apps.json'):
                self.assertFalse((config / name).is_symlink())
                self.assertEqual((config / name).read_bytes(), (self.desired / name).read_bytes())
            self.assertEqual((credentials / 'cakey.pem').read_text(), 'private data')


class SunshineTemplateGuardTests(unittest.TestCase):
    def test_preserves_unmanaged_templates(self):
        for device in ('iphone', 'ipad'):
            with self.subTest(device=device), tempfile.TemporaryDirectory() as d:
                directory = Path(d) / 'sunshine-managed' / device
                directory.mkdir(parents=True)
                target = directory / 'apps.json'

                def check():
                    return subprocess.run(['bash', str(TEMPLATE_GUARD), str(directory), device],
                                          capture_output=True).returncode

                self.assertEqual(check(), 0)
                target.write_text('local template')
                self.assertNotEqual(check(), 0)
                self.assertEqual(target.read_text(), 'local template')
                target.unlink()
                target.symlink_to('/nix/store/test-home-manager-files/.local/share/sunshine-managed/'
                                  + device + '/apps.json')
                self.assertEqual(check(), 0)


if __name__ == '__main__':
    unittest.main()
