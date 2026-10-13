import os
from pathlib import Path
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]


class DeploymentAuthTests(unittest.TestCase):
    def test_token_is_loaded_once_and_existing_settings_are_preserved(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            gh = root / 'gh'
            gh.write_text('#!/bin/sh\nprintf "%s\\n" call >> "$AUTH_CALL_LOG"\nprintf fixture-token\n')
            gh.chmod(0o755)
            nix = root / 'nix'
            nix.write_text('#!/bin/sh\nprintf "%s\\n" "gitlab.com=other-token github.com=old-token"\n')
            nix.chmod(0o755)
            env = dict(os.environ, PATH=directory + ':/usr/bin:/bin',
                       AUTH_CALL_LOG=str(root / 'calls'),
                       NIX_CONFIG='max-jobs = 2\naccess-tokens = gitlab.com=other-token')
            result = subprocess.run(['/bin/bash', '-c',
                                     'source scripts/setup.sh; configure_nix_github_token; printf "%s" "$NIX_CONFIG"'],
                                    cwd=ROOT, env=env, capture_output=True, text=True, check=True)
            self.assertEqual(result.stdout, env['NIX_CONFIG'] + '\naccess-tokens = github.com=fixture-token gitlab.com=other-token')
            self.assertEqual((root / 'calls').read_text(), 'call\n')

    def test_unavailable_login_keeps_existing_configuration(self):
        with tempfile.TemporaryDirectory() as directory:
            gh = Path(directory) / 'gh'
            gh.write_text('#!/bin/sh\nexit 1\n')
            gh.chmod(0o755)
            env = dict(os.environ, PATH=directory + ':/usr/bin:/bin', NIX_CONFIG='max-jobs = 2')
            result = subprocess.run(['/bin/bash', '-c',
                                     'source scripts/setup.sh; configure_nix_github_token; printf "%s" "$NIX_CONFIG"'],
                                    cwd=ROOT, env=env, capture_output=True, text=True, check=True)
            self.assertEqual(result.stdout, env['NIX_CONFIG'])

    def test_first_deploy_without_existing_tokens(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for name, body in [('gh', 'printf fixture-token'), ('nix', 'printf "\\n"')]:
                executable = root / name
                executable.write_text('#!/bin/sh\n' + body + '\n')
                executable.chmod(0o755)
            env = dict(os.environ, PATH=directory + ':/usr/bin:/bin')
            env.pop('NIX_CONFIG', None)
            result = subprocess.run(['/bin/bash', '-c',
                                     'source scripts/setup.sh; configure_nix_github_token; printf "%s" "$NIX_CONFIG"'],
                                    cwd=ROOT, env=env, capture_output=True, text=True, check=True)
            self.assertEqual(result.stdout, 'access-tokens = github.com=fixture-token')

    def test_shell_renderers_do_not_load_github_credentials(self):
        source = (ROOT / 'home/env.nix').read_text()
        self.assertNotIn('gh auth token', source)
        self.assertNotIn('NIX_CONFIG', source)
        self.assertNotIn('ZSH_EXECUTION_STRING', source)


if __name__ == '__main__':
    unittest.main()
