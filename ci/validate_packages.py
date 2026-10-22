#!/usr/bin/env python3
"""Validate the literal package arrays in new_mac_setup.sh without executing it."""
import argparse
import concurrent.futures
import re
import sys
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

ARRAY_NAMES = ("packages", "mas_packages", "dmg_apps")


def extract(text, name):
    match = re.search(rf"(?m)^{name}=\(\s*\n(.*?)^\)", text, re.S | re.M)
    if not match:
        raise ValueError(f"Missing array: {name}")
    entries = []
    for line in match.group(1).splitlines():
        line = line.strip()
        if not line or line.startswith('#'):
            continue
        match_entry = re.fullmatch(r'"([^"\n]+)"\s*(?:#.*)?', line)
        if not match_entry:
            raise ValueError(f"Unsupported array entry in {name}: {line}")
        entries.append(match_entry.group(1))
    return entries


def check_remote(item):
    # Explicit Homebrew tap formulae cannot be queried with the public default catalog.
    if item.count('/') == 2:
        return item, 'SKIP (third-party tap)'
    token = urllib.parse.quote(item, safe='@+-')
    for kind in ('formula', 'cask'):
        url = f'https://formulae.brew.sh/api/{kind}/{token}.json'
        try:
            with urllib.request.urlopen(urllib.request.Request(url, headers={'User-Agent': 'os-scripts-ci'}), timeout=12) as response:
                if response.status == 200:
                    return item, f'OK ({kind})'
        except urllib.error.HTTPError as exc:
            if exc.code != 404:
                return item, f'NETWORK ERROR: HTTP {exc.code}'
        except (urllib.error.URLError, TimeoutError) as exc:
            return item, f'NETWORK ERROR: {exc}'
    return item, 'UNKNOWN (neither formula nor cask)'


def main():
    parser = argparse.ArgumentParser()
    modes = parser.add_mutually_exclusive_group(required=True)
    modes.add_argument('--offline', action='store_true')
    modes.add_argument('--online', action='store_true')
    parser.add_argument('script', type=Path)
    args = parser.parse_args()
    try:
        text = args.script.read_text(encoding='utf-8')
        arrays = {name: extract(text, name) for name in ARRAY_NAMES}
    except (OSError, ValueError) as exc:
        parser.error(str(exc))
    errors = []
    for name, values in arrays.items():
        print(f'{name}: {len(values)} entries')
        seen = set()
        for value in values:
            if value in seen:
                errors.append(f'{name}: duplicate {value}')
            seen.add(value)
    for value in arrays['mas_packages']:
        if not re.fullmatch(r'\d{6,15}', value):
            errors.append(f'Invalid MAS ID: {value}')
    for value in arrays['dmg_apps']:
        name, separator, url = value.partition('|')
        if not name or not separator or not url.startswith('https://'):
            errors.append(f'Invalid DMG entry: {value}')
    if args.online:
        with concurrent.futures.ThreadPoolExecutor(max_workers=8) as pool:
            for item, result in pool.map(check_remote, arrays['packages']):
                print(f'{item}: {result}')
                if result.startswith(('UNKNOWN', 'NETWORK ERROR')):
                    errors.append(f'{item}: {result}')
    for error in errors:
        print(f'ERROR: {error}', file=sys.stderr)
    return 1 if errors else 0


if __name__ == '__main__':
    sys.exit(main())
