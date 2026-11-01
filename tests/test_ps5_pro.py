import importlib.machinery
import importlib.util
from pathlib import Path
import runpy
import subprocess
import unittest
from unittest.mock import call, patch


SCRIPT = Path(__file__).resolve().parents[1] / "bins/ps5-pro"
loader = importlib.machinery.SourceFileLoader("ps5_pro", str(SCRIPT))
spec = importlib.util.spec_from_loader(loader.name, loader)
ps5_pro = importlib.util.module_from_spec(spec)
loader.exec_module(ps5_pro)


class WakeTests(unittest.TestCase):
    @patch.object(ps5_pro.time, "sleep")
    @patch.object(ps5_pro.time, "monotonic", side_effect=[0, 1])
    @patch.object(ps5_pro, "registration_key", return_value="12345678")
    @patch.object(ps5_pro, "state", side_effect=["standby", "ready"])
    @patch.object(ps5_pro, "run")
    def test_standby_wakes_without_touching_existing_instances(
        self, run, state, registration_key, monotonic, sleep
    ):
        ps5_pro.wake()
        run.assert_called_once_with(
            ps5_pro.CLI + ["wakeup", "--ps5", "--host=" + ps5_pro.HOST,
                           "--registkey=12345678"]
        )
        sleep.assert_called_once_with(2)

    @patch.object(ps5_pro, "registration_key")
    @patch.object(ps5_pro, "state", return_value="ready")
    @patch.object(ps5_pro, "run")
    def test_ready_console_does_not_send_wake(self, run, state, registration_key):
        ps5_pro.wake()
        run.assert_not_called()
        registration_key.assert_not_called()

    @patch.object(ps5_pro.Path, "exists", return_value=True)
    @patch.object(ps5_pro.time, "sleep")
    @patch.object(ps5_pro.time, "monotonic", side_effect=[0, 36])
    @patch.object(ps5_pro, "registration_key", return_value="12345678")
    @patch.object(ps5_pro, "state", return_value="standby")
    @patch.object(ps5_pro, "run")
    def test_unconfirmed_wake_notifies_without_killing_sessions(
        self, run, state, registration_key, monotonic, sleep, exists
    ):
        ps5_pro.wake()
        self.assertEqual(run.call_args_list, [
            call(ps5_pro.CLI + ["wakeup", "--ps5", "--host=" + ps5_pro.HOST,
                                "--registkey=12345678"]),
            call(["/usr/bin/notify-send", "PS5 PRO",
                  "Wake-up was not confirmed. Opening Remote Play."]),
        ])

    @patch("os.execv")
    @patch("subprocess.run", side_effect=subprocess.TimeoutExpired("flatpak", 8))
    @patch("sys.argv", [str(SCRIPT)])
    def test_discovery_timeout_still_opens_chiaki(self, run, execv):
        runpy.run_path(str(SCRIPT), run_name="__main__")
        execv.assert_called_once_with(ps5_pro.FLATPAK[0], ps5_pro.FLATPAK + [ps5_pro.APP])


if __name__ == "__main__":
    unittest.main()
