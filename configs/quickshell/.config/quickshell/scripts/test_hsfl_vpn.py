"""Run with python3 -m unittest discover -s scripts -p 'test_hsfl_vpn.py'."""

import importlib.util
from pathlib import Path
import subprocess
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location(
    "hsfl_vpn", Path(__file__).with_name("hsfl-vpn.py")
)
vpn = importlib.util.module_from_spec(spec)
spec.loader.exec_module(vpn)

AUTH = (
    "COOKIE='session-secret'\nCONNECT_URL='https://vpn.hs-flensburg.de/group'\n"
    "FINGERPRINT='sha256:certificate'\nRESOLVE='vpn.hs-flensburg.de:192.0.2.1'\n"
)


class VpnTests(unittest.TestCase):
    def test_auth_is_parsed_without_evaluating_shell(self):
        result = vpn.parse_auth(AUTH.replace("session-secret", "$(touch /tmp/no);`id`"))
        self.assertEqual(result["COOKIE"], "$(touch /tmp/no);`id`")

    def test_incomplete_or_multiline_secrets_are_rejected(self):
        for output in ("COOKIE='only-a-cookie'", AUTH.replace("session-secret", "one\rsecond")):
            with self.subTest(output=output), self.assertRaises(RuntimeError):
                vpn.parse_auth(output)

    def test_profile_lookup_uses_uuid_and_checks_vpn_type(self):
        with patch.object(vpn, "nmcli", side_effect=[
            "other:802-3-ethernet\nvpn-id:vpn", vpn.PROFILE, vpn.SERVICE,
        ]):
            self.assertEqual(vpn.profile_uuid(), "vpn-id")
        with patch.object(vpn, "nmcli", side_effect=[
            "vpn-id:vpn", vpn.PROFILE, "org.freedesktop.NetworkManager.openvpn",
        ]), self.assertRaises(RuntimeError):
            vpn.profile_uuid()

    def test_profile_creation_disables_saved_secrets_and_autoconnect(self):
        with patch.object(vpn, "profile_uuid", side_effect=[None, "vpn-id"]), \
                patch.object(vpn, "nmcli") as nmcli:
            self.assertEqual(vpn.ensure_profile(), "vpn-id")
        args = nmcli.call_args.args
        self.assertEqual(args[args.index("connection.permissions") + 1], "")
        self.assertEqual(args[args.index("connection.autoconnect") + 1], "no")
        data = args[args.index("vpn.data") + 1]
        self.assertIn("mtu=1280", data)
        for secret in ("cookie", "gateway", "gwcert", "resolve"):
            self.assertIn(f"{secret}-flags=2", data)

    def test_existing_private_profile_is_repaired_before_login(self):
        with patch.object(vpn, "profile_uuid", return_value="vpn-id"), \
                patch.object(vpn, "nmcli", return_value="user:gws") as nmcli:
            self.assertEqual(vpn.ensure_profile(), "vpn-id")
        self.assertEqual(nmcli.call_count, 3)
        nmcli.assert_any_call(
            "connection", "modify", "uuid", "vpn-id", "connection.permissions", ""
        )
        nmcli.assert_called_with("connection", "modify", "uuid", "vpn-id", "+vpn.data", "mtu=1280")

    def test_existing_shared_profile_gets_mtu_without_replacing_other_settings(self):
        with patch.object(vpn, "profile_uuid", return_value="vpn-id"), \
                patch.object(vpn, "nmcli", return_value="") as nmcli:
            self.assertEqual(vpn.ensure_profile(), "vpn-id")
        self.assertEqual(nmcli.call_count, 2)
        nmcli.assert_any_call(
            "-g", "connection.permissions", "connection", "show", "uuid", "vpn-id"
        )
        nmcli.assert_called_with("connection", "modify", "uuid", "vpn-id", "+vpn.data", "mtu=1280")

    def test_connection_status_tracks_only_our_uuid(self):
        with patch.object(vpn, "nmcli", return_value="other:activated\nvpn-id:activating"):
            self.assertEqual(vpn.connection_state("vpn-id"), "connecting")
        with patch.object(vpn, "nmcli", return_value="other:activated"):
            self.assertEqual(vpn.connection_state("vpn-id"), "disconnected")

    def test_cookie_goes_through_stdin_and_keeps_redirect_and_resolve(self):
        with patch.object(vpn.shutil, "which", return_value="/usr/bin/openconnect"), \
                patch.object(vpn, "PLUGIN") as plugin, \
                patch.object(vpn, "ensure_profile", return_value="vpn-id"), \
                patch.object(vpn, "connection_state", return_value="disconnected"), \
                patch.object(vpn.subprocess, "run") as run:
            plugin.is_file.return_value = True
            run.return_value.stdout = AUTH
            vpn.connect()
        auth_call, activate_call = run.call_args_list
        self.assertIn("--authgroup=HSFL-Studierende", auth_call.args[0])
        self.assertNotIn("session-secret", " ".join(activate_call.args[0]))
        secrets = activate_call.kwargs["input"]
        self.assertIn("vpn.secrets.cookie:session-secret\n", secrets)
        self.assertIn("vpn.secrets.gateway:https://vpn.hs-flensburg.de/group\n", secrets)
        self.assertIn("vpn.secrets.resolve:vpn.hs-flensburg.de:192.0.2.1\n", secrets)
        self.assertIn("/dev/stdin", activate_call.args[0])

    def test_failed_login_does_not_activate_a_tunnel(self):
        with patch.object(vpn.shutil, "which", return_value="/usr/bin/openconnect"), \
                patch.object(vpn, "PLUGIN") as plugin, \
                patch.object(vpn, "ensure_profile", return_value="vpn-id"), \
                patch.object(vpn, "connection_state", return_value="disconnected"), \
                patch.object(vpn.subprocess, "run") as run:
            plugin.is_file.return_value = True
            run.side_effect = subprocess.CalledProcessError(1, ["openconnect"])
            with self.assertRaises(subprocess.CalledProcessError):
                vpn.connect()
            self.assertEqual(run.call_count, 1)

    def test_disconnect_does_not_touch_other_connections(self):
        with patch.object(vpn, "profile_uuid", return_value="vpn-id"), \
                patch.object(vpn, "connection_state", return_value="connected"), \
                patch.object(vpn, "nmcli") as nmcli:
            vpn.disconnect()
        nmcli.assert_called_once_with("connection", "down", "uuid", "vpn-id")


if __name__ == "__main__":
    unittest.main()
