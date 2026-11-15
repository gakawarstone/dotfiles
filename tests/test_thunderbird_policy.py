"""Exercise the system-policy installer inside a disposable filesystem tree."""
from pathlib import Path
import os
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
INSTALLER = ROOT / "scripts/install_thunderbird_policy.sh"
GUARD = ROOT / "nix/home/gws/check-thunderbird-policy-target.sh"


class PolicyInstallerTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.source = self.root / "managed.json"
        self.source.write_text('{"policies": {}}\n')
        self.target = self.root / "etc/thunderbird/policies/policies.json"
        self.distribution = self.root / "usr/lib/thunderbird/distribution/policies.json"
        self.env = dict(os.environ, THUNDERBIRD_POLICY_TEST_ROOT=str(self.root))

    def install(self):
        return subprocess.run(["bash", str(INSTALLER), str(self.source)], env=self.env, capture_output=True)

    def test_installs_idempotently(self):
        self.assertEqual(self.install().returncode, 0)
        self.assertTrue(self.target.is_symlink())
        self.assertEqual(os.readlink(self.target), str(self.source))
        self.assertEqual(self.install().returncode, 0)

    def test_preserves_existing_policy_and_dangling_link(self):
        self.target.parent.mkdir(parents=True)
        self.target.write_text("local policy\n")
        self.assertNotEqual(self.install().returncode, 0)
        self.assertEqual(self.target.read_text(), "local policy\n")
        self.target.unlink()
        self.target.symlink_to("missing-local-policy")
        self.assertNotEqual(self.install().returncode, 0)
        self.assertEqual(os.readlink(self.target), "missing-local-policy")

    def test_preserves_distribution_policy(self):
        self.distribution.parent.mkdir(parents=True)
        self.distribution.write_text("other policy\n")
        self.assertNotEqual(self.install().returncode, 0)
        self.assertEqual(self.distribution.read_text(), "other policy\n")
        self.assertFalse(self.target.exists())

    def test_rejects_missing_source_and_linked_directory(self):
        self.source.unlink()
        self.assertNotEqual(self.install().returncode, 0)
        self.source.write_text("{}")
        etc = self.root / "etc"
        etc.mkdir()
        other = self.root / "other"
        other.mkdir()
        (etc / "thunderbird").symlink_to(other, target_is_directory=True)
        self.assertNotEqual(self.install().returncode, 0)
        self.assertEqual(list(other.iterdir()), [])


class PolicyOwnershipTests(unittest.TestCase):
    def test_preserves_local_policy_and_allows_managed_target(self):
        with tempfile.TemporaryDirectory() as tmp:
            directory = Path(tmp) / "thunderbird-dotfiles"
            directory.mkdir()
            target = directory / "policies.json"

            def check():
                return subprocess.run(["bash", str(GUARD), str(directory)], capture_output=True).returncode

            self.assertEqual(check(), 0)
            target.write_text("local policy\n")
            self.assertNotEqual(check(), 0)
            self.assertEqual(target.read_text(), "local policy\n")
            target.unlink()
            target.symlink_to("/nix/store/test-home-manager-files/.local/share/thunderbird-dotfiles/policies.json")
            self.assertEqual(check(), 0)


if __name__ == "__main__":
    unittest.main()
