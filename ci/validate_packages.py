#!/usr/bin/env python3
"""Validate the literal package arrays in new_mac_setup.sh without executing it."""
import argparse
import concurrent.futures
import json
import re
import sys
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


def fetch_catalog(kind):
    # Per-package endpoints do not resolve aliases such as "python".
    url = f'https://formulae.brew.sh/api/{kind}.json'
    request = urllib.request.Request(url, headers={'User-Agent': 'os-scripts-ci'})
    with urllib.request.urlopen(request, timeout=30) as response:
        entries = json.load(response)
    if not isinstance(entries, list) or not entries:
        raise ValueError(f'Invalid {kind} catalog: expected a non-empty list')
    name_key = 'name' if kind == 'formula' else 'token'
    alternate_keys = ('aliases', 'oldnames') if kind == 'formula' else ('old_tokens',)
    catalog = {}
    for entry in entries:
        canonical = entry[name_key]
        if not isinstance(canonical, str) or not canonical:
            raise ValueError(f'Invalid {kind} package name')
        catalog[canonical] = (kind, canonical)
    # Current names take precedence over historical names.
    for entry in entries:
        for key in alternate_keys:
            for name in entry.get(key, []):
                catalog.setdefault(name, (kind, entry[name_key]))
    return catalog


def load_catalogs():
    catalog = {}
    with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
        catalogs = list(pool.map(fetch_catalog, ('formula', 'cask')))
    # A formula alias must not shadow a current cask token (e.g. onedrive).
    for entries in catalogs:
        for name, package in entries.items():
            if name == package[1]:
                catalog.setdefault(name, package)
    for entries in catalogs:
        for name, package in entries.items():
            catalog.setdefault(name, package)
    return catalog


def check_remote(item, catalog):
    # Explicit Homebrew tap formulae cannot be queried with the public default catalog.
    if item.count('/') == 2:
        return item, 'SKIP (third-party tap)'
    if item in catalog:
        kind, canonical = catalog[item]
        resolved = f': {canonical}' if item != canonical else ''
        return item, f'OK ({kind}{resolved})'
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
        try:
            catalog = load_catalogs()
        except (OSError, ValueError, KeyError, TypeError) as exc:
            errors.append(f'Unable to load Homebrew catalogs: {exc}')
        else:
            for item in arrays['packages']:
                item, result = check_remote(item, catalog)
                print(f'{item}: {result}')
                if result.startswith('UNKNOWN'):
                    errors.append(f'{item}: {result}')
    for error in errors:
        print(f'ERROR: {error}', file=sys.stderr)
    return 1 if errors else 0


if __name__ == '__main__':
    sys.exit(main())
