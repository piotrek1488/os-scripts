#!/usr/bin/env python3
"""Offline validation of package manifests for the linux branch."""
from pathlib import Path
from urllib.parse import urlsplit
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
CATEGORIES = ("essentials", "dev", "entertainment")
NAME = re.compile(r"^[a-z0-9][a-z0-9+.-]*$")
errors = []

for source in ("apt", "snap", "deb"):
    seen = {}
    for category in CATEGORIES:
        path = ROOT / "packages" / source / f"{category}.txt"
        if not path.is_file():
            errors.append(f"Missing {path.relative_to(ROOT)}")
            continue
        for lineno, raw in enumerate(path.read_text(encoding="utf-8-sig").splitlines(), 1):
            # Mirrors install.sh: comments begin with #, trailing CR is ignored.
            line = raw.split("#", 1)[0].strip()
            if not line or line.startswith("#"):
                continue
            if source == "deb":
                # Keep parsing aligned with install.sh: # starts a comment.
                parts = line.split()
                url = parts[0] if parts else ""
                parsed = urlsplit(url)
                valid = (len(parts) == 1 and parsed.scheme == "https" and
                         bool(parsed.netloc) and bool(parsed.path.strip("/")) and
                         not parsed.username and not parsed.password)
                item = url
            else:
                parts = line.split()
                item = parts[0] if parts else ""
                valid = bool(NAME.fullmatch(item)) and (
                    len(parts) == 1 or (source == "snap" and parts[1:] == ["--classic"])
                )
            if not valid:
                errors.append(f"{path.relative_to(ROOT)}:{lineno}: invalid {source} entry")
                continue
            # Repeated entries are allowed by the installer (deduplicated), but are
            # reported as warnings so existing manifests don't need rewriting.
            if item in seen:
                print(f"WARNING duplicate {source} entry: {item} ({seen[item]} and {category}:{lineno})")
            else:
                seen[item] = f"{category}:{lineno}"
    print(f"{source.upper()}: {len(seen)} unique entries")

if errors:
    print("\n".join(errors), file=sys.stderr)
    sys.exit(1)
print("OK: package manifests are syntactically valid (offline).")
