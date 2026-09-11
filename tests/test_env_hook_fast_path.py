import pathlib
import subprocess
import tempfile
import unittest


class HookShellStartupTests(unittest.TestCase):
    def test_only_the_activity_notification_skips_user_initialization(self):
        source = (pathlib.Path(__file__).parents[1] / 'home/env.nix').read_text()
        body = source.split('home.file.".zshenv".text = ', 1)[1]
        guard = body[body.index('case '):body.index('esac') + 4].replace("''${", '${')
        with tempfile.TemporaryDirectory() as directory:
            root = pathlib.Path(directory)
            hook = root / 'Projects/MyClaw/scripts/agent_awake_manager.py'
            hook.parent.mkdir(parents=True)
            hook.write_text('#!/bin/sh\nexit 0\n')
            hook.chmod(0o755)
            (root / '.zshenv').write_text(guard + '\nprint initialized >&2\n')
            for command, skipped in [(f'{hook} hook codex', True),
                                     (f'{hook} hook claude', False),
                                     (f'{hook} hook codex; :', False), (':', False)]:
                with self.subTest(command=command):
                    result = subprocess.run(['/bin/zsh', '-c', command],
                                            env={'HOME': directory, 'ZDOTDIR': directory, 'PATH': '/usr/bin:/bin'},
                                            capture_output=True, text=True, check=True)
                    self.assertEqual('initialized' not in result.stderr, skipped)


if __name__ == '__main__':
    unittest.main()
