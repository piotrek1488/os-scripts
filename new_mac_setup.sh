#!/bin/bash

# ------------------------------------------------------------------------------
# Script Name: new_mac_setup.sh
#
# Description: 
#   This script checks if Homebrew is installed on your macOS system.
#   If not, it installs Homebrew, sets up the PATH, and then installs a list
#   of specified packages as either casks or formulas.
#
# Author: Darrell Moore Jr (DJ)
# Date Created: 2025-02-18
#
# Usage: 
#   Run this script from the terminal:
#       ./new_mac_setup.sh
#
# Requirements:
#   - macOS with Bash installed.
#   - Internet connection.
#
# License: MIT License
#
# Notes:
#   - Make sure that your dash characters are standard hyphens.
#   - Adjust the package list to your own needs.
#   - Error logs are written out to the directory from where the script is run.
#   - The script will append to the log file if it already exists.
# ------------------------------------------------------------------------------


# VARIABLES   ------------------------------------------------------------------
# List of packages to install
# https://formulae.brew.sh/formula/
# https://formulae.brew.sh/cask/
packages=(
    "python"
    "ffmpeg-full"
    "git"
    "gh"
    "wget"
    "coreutils"
    "tree"
    "docker"
    "docker-desktop"
    "colima"
    "pyenv"
    "zsh-completion"
    "docker-compose"
    "pyenv-virtualenv"
    "thefuck"
    "highlight"
    "ssh-copy-id"
    "zsh-syntax-highlighting"
    "speedtest-cli"
    "spellcheck"
    "rename"
    "curl"
    "trash"
    "visual-studio-code"
    "chatgpt"
    # "discord"
    "telegram"
    "signal"
    # "whiskey"
    # "rectangle"
    "wins"
    "neohtop"
    "rocket"
    "macwhisper"
    "font-monaspace-nerd-font"
    # "quicklook-json" # disabled
    "keyclu"
    "surfshark"
    "chrome-browser"
    "transnomino"
    "sketchybar"
    "raycast"
    "stremioservice"
    "stremio"
    "qbittorrent@lt20"
    # "steam"
    # "epic-games"
    "alt-tab"
    # "cheatsheet"
    "keyclu"
    "clipgrab"
    "jdownloader"
    "copyclip"
    "db-browser-for-sqlite"
    "yq"
    "jq"
    "sqlite"
    "hiddenbar"
    "karabiner-elements"
    "latest"
    "linearmouse"
    "monitorcontrol"
    # "parallels"
    "shottr"
    "whatsapp"
    "caffeine"
    "appcleaner"
    "TheBoredTeam/boring-notch/boring-notch"
    "cmdx"
    "micro"
    "onecast"
    "iina"
    "heroic"
    # need SUDO:
    # "gog-galaxy"
    "google-drive"
    "onedrive"
    "adguard"
    "logi-options+"
    "displaylink"
    "adobe-acrobat-reader"
    "microsoft-office"
    "microsoft-teams"
    "microsoft-outlook"
    # "amazon-luna" # disabled
)

# Mac App Store apps — check ID with: mas search <name>
mas_packages=(
    "6745342698"  # uBlock Origin Lite
    "1568262835"  # Super Agent for Safari
    "497799835"   # Xcode
    "571213070"   # DaVinci Resolve
    "545519333"   # Prime Video
    "1294126402"  # HEIC Converter
    "1221250572"  # Xnip
    "1160374471"  # Pipifier
    "1236567663"  # Panels
    # "1423210932"  # NextPad
    "545519333"   # Amazon Prime Video
    "408981434"  # iMovie
    "361285480"  # Keynote
    "361304891"  # Numbers
    "361309726"  # Pages
    # "823766827"  # OneDrive
    # "1437809329"  # Surfshark
    # "747648890"  # Telegram
    # "310633997"  # WhatsApp
    # "595191960"   # CopyClip
    # "1452453066"  # Hidden Bar


)

# Apps downloaded as DMG outside of App Store
dmg_apps=(
    # format: "Name|URL_to_DMG"
    # "WindiskWriter|https://github.com/TechUnRestricted/WinDiskWriter/releases/download/v1.3/WinDiskWriter.v1.3_Tahoe_26.0+.Apple_Silicon.zip"
    # "BoringNotch|https://github.com/TheBoredTeam/boring.notch/releases/latest/download/boringNotch.dmg"
    # "ClipGrab|https://download.clipgrab.org/ClipGrab-3.9.16.dmg"
    # "qBittorrent|https://github.com/qbittorrent/qBittorrent/releases/download/release-5.2.0/qbittorrent-5.2.0_lt20.dmg"
    "nextpad-plus-plus|https://github.com/nextpad-plus-plus/nextpad-plus-plus-macos/releases/download/v1.0.6/Nextpad++v1.0.6.dmg"
    # "cmdx|https://github.com/YONN2222/cmdX/releases/download/1.3/cmdX.dmg"
)


# FUNCTIONS --------------------------------------------------------------------

# Function to install Homebrew
# Uses official Homebrew install script from GitHub
function install_brew {
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
}

# Function to set up Homebrew in PATH
# Different paths for Intel vs Apple Silicon Macs
function setup_path {
    # Append to .zprofile (create if doesn't exist)
    if ! echo >> "$HOME/.zprofile"; then
        echo -e "\nFailed to write to .zprofile\n"
        return 1
    fi
    
    # Determine correct Homebrew path based on CPU architecture
    if [[ "$(uname -m)" == "arm64" ]]; then
        BREW_PATH="/opt/homebrew/bin/brew"    # Path for Apple Silicon
    else
        BREW_PATH="/usr/local/bin/brew"       # Path for Intel
    fi
    
    # Add Homebrew to PATH and apply changes
    echo "eval \"\$(${BREW_PATH} shellenv)\"" >> "$HOME/.zprofile"
    eval "$(${BREW_PATH} shellenv)"
    export PATH
    echo -e "\nPATH has been set to include Homebrew.\n"
}

# Function

function error_logging {
    local package_name="$1"
    local file_name="new_mac_setup_log_file.txt"
    formatted_date=$(date "+%Y-%m-%d %H:%M:%S - $package_name")

    # Check if the file exists
    if [ ! -f "$file_name" ]; then
        echo -e "\nFile does not exist. Creating it...\n"
        touch "$file_name" # Create the file
        echo "This is the log of errors that occurred during " \ 
        "the script execution." > "$file_name"
    else
        echo -e "\nFile exists. Will append to it.\n"
    fi

    # Append content to the file
    echo "$formatted_date" >> "$file_name"
    echo -e "\nFailed to install cask: $package_name\n"
}

# Function to install all packages from the packages array
# Detects whether each package should be installed as a cask or formula
function install_packages {
    local success=true
    for package in "${packages[@]}"; do
        # Check if package is available as a cask
        if brew info --cask "$package" &> /dev/null; then
            echo -e "\nInstalling cask: $package\n"
            brew install --cask "$package"
            if [[ $? -ne 0 ]]; then
                echo "Failed to install cask: $package"
                error_logging "$package" # Log the package that did not install 
                success=false
            fi
        # If not a cask, check if it's available as a formula
        elif brew info "$package" &> /dev/null; then
            echo "Installing formula: $package"
            brew install "$package"
            if [[ $? -ne 0 ]]; then
                echo -e "\nFailed to install formula: $package\n"
                success=false
            fi
        else
            echo -e "\nPackage $package not found in Homebrew repositories.\n"
            success=false
        fi
    done
    
    # Return overall success/failure status
    if [[ $success = true ]]; then
        return 0
    else
        return 1
    fi
}

function install_mas_packages {
    if ! command -v mas &>/dev/null; then
        echo "Installing mas..."
        brew install mas
    fi

    for app_id in "${mas_packages[@]}"; do
        echo "Installing from App Store: $app_id"
        if ! mas install "$app_id"; then
            echo "Error occurred while installing: $app_id"
            error_logging "mas:$app_id"
        fi
    done
}

function install_dmg_apps {
    for entry in "${dmg_apps[@]}"; do
        local name="${entry%%|*}"
        local url="${entry##*|}"
        local tmp="/tmp/${name}.dmg"

        echo "Downloading $name..."
        if ! curl -L "$url" -o "$tmp"; then
            echo "Failed to download: $name"
            error_logging "$name"
            continue
        fi

        echo "Mounting $name..."
        local mount_point
        mount_point=$(hdiutil attach "$tmp" -nobrowse -quiet | tail -1 | awk '{print $NF}')

        if [ -z "$mount_point" ]; then
            echo "Failed to mount: $tmp"
            error_logging "$name"
            rm -f "$tmp"
            continue
        fi

        echo "Copying $name to /Applications..."
        cp -r "$mount_point"/*.app /Applications/ 2>/dev/null || \
            echo "No .app found in $mount_point — please check manually."

        hdiutil detach "$mount_point" -quiet
        rm -f "$tmp"
        echo "$name installed."
    done
}

# MAIN ------------------------------------------------------------------------

# Track if this is a new Homebrew installation
new_install="false"

echo "Starting Homebrew and package setup..."

# Check if Homebrew is already installed
echo "Checking if Homebrew is installed..."
if command -v brew >/dev/null 2>&1; then
    echo "Homebrew is already installed."
else
    echo "Homebrew is not installed. Installing Homebrew..."
    install_brew
    new_install="true"
    if [[ $? -ne 0 ]]; then
        echo "Failed to install Homebrew. Please check your internet connection and try again."
        exit 1
    fi
    setup_path
    if [[ $? -ne 0 ]]; then
        echo "Failed to set up PATH. Please check your internet connection and try again."
        exit 1
    fi
fi

# Update Homebrew if it's not a new installation
echo "Updating Homebrew..."
if [[ $new_install = "true" ]]; then    # Using string comparison instead of -eq
    echo "Homebrew was just installed. Skipping update."
else
    if ! brew update; then
        echo "Failed to update Homebrew."
        exit 1
    fi
fi

# Install all specified packages
echo -e "\nInstalling BREW packages...\n"
install_packages
echo -e "\nInstalling MAS packages...\n"
install_mas_packages
echo -e "\nInstalling DMG packages...\n"
install_dmg_apps

echo -e "Do you want to download .zshrc, .zshrc.userand .zsh_aliases files from GitHub? (y/n)"
read -r response
if [[ "$response" == "y" || "$response" == "Y"  || "$response" == "yes" || "$response" == "YES" ]]; then
    echo "Downloading .zshrc..."
    curl -o ~/.zshrc https://raw.githubusercontent.com/piotrek1488/macos-scripts/refs/heads/main/zsh_config_files/.zshrc
    echo "Downloading .zshrc.user..."
    curl -o ~/.zshrc.user https://raw.githubusercontent.com/piotrek1488/macos-scripts/refs/heads/main/zsh_config_files/.zshrc.user
    echo "Downloading .zsh_aliases..."
    curl -o ~/.zsh_aliases https://raw.githubusercontent.com/piotrek1488/macos-scripts/refs/heads/main/zsh_config_files/.zsh_aliases
fi

echo -e "Script completed.\n"