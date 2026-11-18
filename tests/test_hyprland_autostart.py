#!/usr/bin/env python3
"""Exercise startup scripts without a running Hyprland session."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

SCRIPTS = Path(__file__).resolve().parents[1] / 'configs/hyprland/.config/hypr'


class AutostartTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.bin = self.root / 'bin'
        self.bin.mkdir()
        self.log = self.root / 'log'
        self.responses = self.root / 'responses'
        self.responses.mkdir()
        self.command('hyprctl', '''\
if [ "$1" = dispatch ]; then
    printf 'dispatch %s\\n' "$2" >> "$TEST_LOG"
    exit 0
fi
[ -f "$TEST_FAIL_HYPRCTL" ] && exit 1
n=0
[ -f "$TEST_COUNT" ] && n=$(cat "$TEST_COUNT")
n=$((n + 1))
printf '%s' "$n" > "$TEST_COUNT"
[ -f "$TEST_RESPONSES/$n" ] && cat "$TEST_RESPONSES/$n" || cat "$TEST_RESPONSES/default"
''')
        for name in ('zen-browser', 'legcord', 't3code-nightly'):
            self.command(name, f'printf "{name} %s\\n" "$*" >> "$TEST_LOG"\n')
        self.command('sleep', ':\n')
        self.env = dict(os.environ, PATH=f'{self.bin}:/usr/bin:/bin',
                        TEST_LOG=str(self.log), TEST_RESPONSES=str(self.responses),
                        TEST_COUNT=str(self.root / 'count'),
                        TEST_FAIL_HYPRCTL=str(self.root / 'fail-hyprctl'))
        (self.responses / 'default').write_text('[]')

    def command(self, name, body):
        path = self.bin / name
        path.write_text('#!/bin/sh\n' + body)
        path.chmod(0o755)

    def clients(self, name, *clients):
        (self.responses / str(name)).write_text(json.dumps(clients))

    def run_script(self, name):
        result = subprocess.run([str(SCRIPTS / name)], env=self.env, capture_output=True,
                                text=True, timeout=30)
        log = self.log.read_text().splitlines() if self.log.exists() else []
        return result, log

    def test_zen_moves_only_the_new_window(self):
        self.clients(1, {'class': 'zen', 'address': '0x1'})
        self.clients(2, {'class': 'zen', 'address': '0x1'},
                     {'class': 'zen', 'address': '0x2'})
        result, log = self.run_script('autostart-zen')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('zen-browser --new-window', log)
        self.assertIn("dispatch hl.dsp.focus({window = 'address:0x2'})", log)
        self.assertIn('dispatch hl.dsp.window.move({workspace = 4})', log)

    def test_legcord_waits_for_both_windows(self):
        self.clients(1, {'class': 'legcord', 'title': 'Discord - Legcord', 'address': '0x3'})
        self.clients(2, {'class': 'org.mozilla.Thunderbird'},
                     {'class': 'legcord', 'title': 'Discord - Legcord', 'address': '0x3'})
        result, log = self.run_script('autostart-legcord')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual((self.root / 'count').read_text(), '2')
        self.assertIn('dispatch hl.dsp.window.move({into_group = \'r\'})', log)

    def test_t3code_waits_for_herdr(self):
        self.clients(2, {'class': 'herdr'})
        result, log = self.run_script('autostart-t3code')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual((self.root / 'count').read_text(), '2')
        self.assertIn('t3code-nightly ', log)

    def test_missing_windows_time_out(self):
        self.clients('default', {'class': 'org.mozilla.Thunderbird'},
                     {'class': 'legcord', 'title': 'Loading', 'address': '0x3'},
                     {'class': 'other'})
        for script in ('autostart-zen', 'autostart-legcord', 'autostart-t3code'):
            with self.subTest(script=script):
                (self.root / 'count').unlink(missing_ok=True)
                self.log.unlink(missing_ok=True)
                result, log = self.run_script(script)
                self.assertEqual((self.root / 'count').read_text(), '300')
                self.assertFalse(any(line.startswith('dispatch ') for line in log))
                if script == 'autostart-t3code':
                    self.assertEqual(result.returncode, 0, result.stderr)
                    self.assertIn('t3code-nightly ', log)
                else:
                    self.assertNotEqual(result.returncode, 0)
                    self.assertIn('timed out', result.stderr)

    def test_second_zen_window_times_out(self):
        self.clients('default', {'class': 'zen', 'address': '0x1'})
        result, log = self.run_script('autostart-zen')
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('second Zen window', result.stderr)
        self.assertEqual((self.root / 'count').read_text(), '301')
        self.assertFalse(any(line.startswith('dispatch ') for line in log))

    def test_failed_second_zen_launch_stops_without_moving_windows(self):
        self.clients(1, {'class': 'zen', 'address': '0x1'})
        self.command('zen-browser', '[ "$1" = --new-window ] && exit 1\nexit 0\n')
        result, log = self.run_script('autostart-zen')
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual((self.root / 'count').read_text(), '1')
        self.assertFalse(any(line.startswith('dispatch ') for line in log))

    def test_dependency_errors_stop_polling_and_t3code_still_starts(self):
        for failure in ('hyprctl', 'jq'):
            with self.subTest(failure=failure):
                if failure == 'hyprctl':
                    (self.root / 'fail-hyprctl').touch()
                else:
                    (self.root / 'fail-hyprctl').unlink()
                    self.command('jq', 'exit 1\n')
                for script in ('autostart-zen', 'autostart-legcord', 'autostart-t3code'):
                    self.log.unlink(missing_ok=True)
                    (self.root / 'count').unlink(missing_ok=True)
                    result, log = self.run_script(script)
                    self.assertFalse(any(line.startswith('dispatch ') for line in log))
                    count = self.root / 'count'
                    self.assertLessEqual(int(count.read_text()) if count.exists() else 0, 1)
                    if script == 'autostart-t3code':
                        self.assertEqual(result.returncode, 0, result.stderr)
                        self.assertIn('t3code-nightly ', log)
                    else:
                        self.assertNotEqual(result.returncode, 0)


if __name__ == '__main__':
    unittest.main()
