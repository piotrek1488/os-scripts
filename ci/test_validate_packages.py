"""Regression tests for catalog lookup and installer tap setup, without installs."""
import contextlib
import io
import json
import subprocess
import tempfile
import unittest
import urllib.error
from pathlib import Path
from unittest import mock

import validate_packages as validator


ROOT = Path(__file__).resolve().parents[1]


class ValidatorTests(unittest.TestCase):
    def setUp(self):
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        self.script = Path(directory.name) / 'setup.sh'
        self.formulae = [
            {'name': 'python@3.15', 'aliases': ['python', 'python3']},
            {'name': 'zsh-completions', 'aliases': ['zsh-completion']},
            {'name': 'aspell', 'oldnames': ['former-spell-checker']},
        ]
        self.casks = [
            {'token': 'google-chrome'},
            {'token': 'font-monaspice-nerd-font',
             'old_tokens': ['font-monaspace-nerd-font']},
        ]
        patcher = mock.patch.object(
            validator.urllib.request, 'urlopen', side_effect=self.response
        )
        self.urlopen = patcher.start()
        self.addCleanup(patcher.stop)

    def response(self, request, timeout):
        catalogs = {
            'https://formulae.brew.sh/api/formula.json': self.formulae,
            'https://formulae.brew.sh/api/cask.json': self.casks,
        }
        return io.BytesIO(json.dumps(catalogs[request.full_url]).encode())

    def run_validator(self, packages, online=True, mas=('497799835',),
                      dmgs=('Example|https://example.com/app.dmg',)):
        arrays = {'packages': packages, 'mas_packages': mas, 'dmg_apps': dmgs}
        self.script.write_text('\n'.join(
            name + '=(\n' + ''.join(f'    "{item}"\n' for item in items) + ')'
            for name, items in arrays.items()
        ), encoding='utf-8')
        argv = ['validate_packages.py', '--online' if online else '--offline',
                str(self.script)]
        stdout, stderr = io.StringIO(), io.StringIO()
        with mock.patch('sys.argv', argv), contextlib.redirect_stdout(stdout), \
                contextlib.redirect_stderr(stderr):
            code = validator.main()
        return code, stdout.getvalue(), stderr.getvalue()

    def test_aliases_and_former_names_succeed_using_two_catalog_requests(self):
        code, stdout, stderr = self.run_validator([
            'python', 'zsh-completion', 'former-spell-checker',
            'font-monaspace-nerd-font', 'google-chrome', 'aspell',
        ])
        self.assertEqual(code, 0, stderr)
        self.assertIn('python: OK (formula: python@3.15)', stdout)
        self.assertIn('zsh-completion: OK (formula: zsh-completions)', stdout)
        self.assertIn('former-spell-checker: OK (formula: aspell)', stdout)
        self.assertIn('font-monaspace-nerd-font: OK (cask: font-monaspice-nerd-font)',
                      stdout)
        self.assertEqual(self.urlopen.call_count, 2)

    def test_unknown_packages_still_fail(self):
        code, stdout, stderr = self.run_validator(['chrome-browser', 'spellcheck'])
        self.assertEqual(code, 1)
        for item in ('chrome-browser', 'spellcheck'):
            self.assertIn(f'{item}: UNKNOWN', stdout)
            self.assertIn(f'ERROR: {item}: UNKNOWN', stderr)

    def test_third_party_packages_are_explicitly_skipped(self):
        packages = ['FelixKratz/formulae/sketchybar', 'YONN2222/cmdx/cmdx',
                    'TheBoredTeam/boring-notch/boring-notch']
        code, stdout, stderr = self.run_validator(packages)
        self.assertEqual(code, 0, stderr)
        for item in packages:
            self.assertIn(f'{item}: SKIP (third-party tap)', stdout)

    def test_offline_mode_does_not_access_the_network(self):
        code, _, stderr = self.run_validator(['python'], online=False)
        self.assertEqual(code, 0, stderr)
        self.urlopen.assert_not_called()

    def test_offline_validation_still_rejects_bad_lists(self):
        code, _, stderr = self.run_validator(
            ['python', 'python'], online=False, mas=('not-an-id',),
            dmgs=('Example|http://example.com/app.dmg',)
        )
        self.assertEqual(code, 1)
        self.assertIn('duplicate python', stderr)
        self.assertIn('Invalid MAS ID', stderr)
        self.assertIn('Invalid DMG entry', stderr)

    def test_network_errors_fail_without_reporting_missing_packages(self):
        failures = [urllib.error.URLError('unavailable'), TimeoutError('timed out'),
                    urllib.error.HTTPError('https://formulae.brew.sh', 503,
                                           'Unavailable', {}, None)]
        for failure in failures:
            with self.subTest(failure=str(failure)):
                self.urlopen.side_effect = failure
                code, stdout, stderr = self.run_validator(['python'])
                self.assertEqual(code, 1)
                self.assertIn('Unable to load Homebrew catalogs', stderr)
                self.assertNotIn('UNKNOWN', stdout + stderr)

    def test_malformed_catalogs_fail_with_a_clear_error(self):
        for payload in (b'<html>unavailable</html>', b'{}', b'[]', b'[{}]'):
            with self.subTest(payload=payload):
                self.urlopen.side_effect = lambda *args, **kwargs: io.BytesIO(payload)
                code, _, stderr = self.run_validator(['python'])
                self.assertEqual(code, 1)
                self.assertIn('Unable to load Homebrew catalogs', stderr)

    def test_current_names_take_precedence_over_former_names(self):
        self.formulae.insert(0, {'name': 'another-formula', 'oldnames': ['aspell']})
        code, stdout, stderr = self.run_validator(['aspell'])
        self.assertEqual(code, 0, stderr)
        self.assertIn('aspell: OK (formula)', stdout)

    def test_formula_alias_does_not_shadow_current_cask(self):
        self.formulae.append({'name': 'onedrive-cli', 'aliases': ['onedrive']})
        self.casks.append({'token': 'onedrive'})
        code, stdout, stderr = self.run_validator(['onedrive'])
        self.assertEqual(code, 0, stderr)
        self.assertIn('onedrive: OK (cask)', stdout)


class InstallerTapTests(unittest.TestCase):
    def run_taps(self, brew_body):
        # Load only function definitions; never run the installer's main section.
        definitions = (ROOT / 'new_mac_setup.sh').read_text().split(
            '# MAIN ------------------------------------------------------------------------'
        )[0]
        return subprocess.run(
            ['/bin/bash', '-c', definitions + '\nbrew() {\n' + brew_body +
             '\n}\ninstall_taps\n'], capture_output=True, text=True, check=False
        )

    def test_taps_use_upstream_sources_including_custom_cmdx_url(self):
        result = self.run_taps('printf "%s\\n" "$*"')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.splitlines(), [
            'tap FelixKratz/formulae',
            'tap TheBoredTeam/boring-notch',
            'tap YONN2222/cmdx https://github.com/YONN2222/cmdX',
        ])

    def test_tap_failure_stops_setup(self):
        result = self.run_taps('printf "%s\\n" "$*"; return 1')
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(result.stdout.splitlines(), ['tap FelixKratz/formulae'])


if __name__ == '__main__':
    unittest.main()
