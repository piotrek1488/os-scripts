#!/usr/bin/env bash

set -e

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"

mkdir -p "$BASE_DIR/packages"
mkdir -p "$BASE_DIR/config"

echo "==> Zbieram pakiety APT..."

apt-mark showmanual \
    | sort \
    > "$BASE_DIR/packages/apt-all-manual.txt"


echo "==> Zbieram Flatpaki..."

if command -v flatpak >/dev/null 2>&1; then
    flatpak list --app --columns=application \
        | sort \
        > "$BASE_DIR/packages/flatpak.txt"
else
    : > "$BASE_DIR/packages/flatpak.txt"
fi


echo "==> Zbieram Snapy..."

if command -v snap >/dev/null 2>&1; then
    snap list \
        | tail -n +2 \
        | awk '{print $1}' \
        | sort \
        > "$BASE_DIR/packages/snap.txt"
else
    : > "$BASE_DIR/packages/snap.txt"
fi


echo "==> Zbieram rozszerzenia GNOME..."

if command -v gnome-extensions >/dev/null 2>&1; then
    gnome-extensions list \
        | sort \
        > "$BASE_DIR/packages/gnome-extensions.txt"
else
    : > "$BASE_DIR/packages/gnome-extensions.txt"
fi


echo "==> Zapisuję ustawienia GNOME..."

if command -v dconf >/dev/null 2>&1; then
    dconf dump / \
        > "$BASE_DIR/config/dconf.ini"
fi


echo
echo "Gotowe."
echo "Sprawdź katalog packages/ przed wrzuceniem do repo."