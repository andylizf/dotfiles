"""Check relay routing without contacting Feishu or reading real credentials."""

import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


WRAPPER = Path(__file__).resolve().parents[1] / "home/scripts/lark-cli-wrapper.sh"


class WrapperRoutingTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        home = Path(self.directory.name)
        binary = home / ".local/bin/lark-cli.real"
        binary.parent.mkdir(parents=True)
        binary.write_text(
            "#!/usr/bin/env python3\n"
            "import json, os, sys\n"
            "print(json.dumps({'argv': sys.argv[1:], "
            "'app': os.getenv('LARKSUITE_CLI_APP_ID'), "
            "'token': os.getenv('LARKSUITE_CLI_USER_ACCESS_TOKEN')}))\n"
        )
        binary.chmod(0o755)
        config = home / ".config/lark-sync"
        (config / "at-cache").mkdir(parents=True)
        (config / "profiles").write_text("first app_first\nsecond app_second\n")
        for name in ["first", "second"]:
            (config / "at-cache" / f"app_{name}").write_text(f"fixture_{name}")
        self.env = {k: v for k, v in os.environ.items() if not k.startswith("LARKSUITE_CLI_")}
        self.env["HOME"] = str(home)

    def run_wrapper(self, *args, profile=None):
        env = dict(self.env)
        if profile is not None:
            env["LARKSUITE_CLI_PROFILE"] = profile
        return subprocess.run(["/bin/bash", str(WRAPPER), *args], env=env, text=True, capture_output=True)

    def test_environment_selects_relay_token(self):
        result = self.run_wrapper("whoami", profile="first")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(result.stdout)["token"], "fixture_first")

    def test_explicit_profile_overrides_environment_in_each_position(self):
        for args in [("--profile", "second", "whoami"), ("whoami", "--profile=second")]:
            with self.subTest(args=args):
                result = self.run_wrapper(*args, profile="first")
                self.assertEqual(json.loads(result.stdout)["token"], "fixture_second")

    def test_offline_commands_do_not_require_or_inject_token(self):
        cases = [("auth", "qrcode", "https://example.test/authorize"),
                 ("auth", "login", "--help"), ("contact", "+get-user", "-h"),
                 ("update", "--check", "--json"), ("update", "--check=true")]
        for args in cases:
            with self.subTest(args=args):
                result = self.run_wrapper(*args, profile="first")
                self.assertEqual(result.returncode, 0, result.stderr)
                data = json.loads(result.stdout)
                self.assertEqual(data["argv"], list(args))
                self.assertIsNone(data["token"])

    def test_upgrade_still_protects_wrapper(self):
        result = self.run_wrapper("--profile", "first", "update")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Restore lark-cli.real", json.loads(result.stdout)["error"]["hint"])

    def test_disabled_boolean_flags_do_not_bypass_protection(self):
        cases = [("update", "--check", "--check=false"),
                 ("update", "--", "--check"),
                 ("auth", "login", "--help", "--help=false")]
        for args in cases:
            with self.subTest(args=args):
                result = self.run_wrapper(*args, profile="first")
                self.assertNotEqual(result.returncode, 0)
                self.assertFalse(json.loads(result.stdout)["ok"])

    def test_login_and_logout_still_use_writer(self):
        for command in ["login", "logout"]:
            with self.subTest(command=command):
                result = self.run_wrapper("auth", command, profile="first")
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("READER", json.loads(result.stdout)["error"]["message"])


if __name__ == "__main__":
    unittest.main()
