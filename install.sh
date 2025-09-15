#!/bin/env bash

GODOTS_DOWNLOAD_URL="https://github.com/MakovWait/godots/releases/latest/download/LinuxX11.zip"
GODOTS_TMP_DIR="/tmp/godots"

GODOTS_INSTALL_DIR="$HOME/.local/godots.app"
GODOTS_BIN_PATH="$GODOTS_INSTALL_DIR/Godots.x86_64"

ICON_DOWNLOAD_URL="https://raw.githubusercontent.com/MakovWait/godots/refs/heads/main/icon.svg"
ICON_PATH="$HOME/.local/godots.app/icon.svg"

try_download() {
	download_url=$1
	path=$2
	if command -v wget &>/dev/null; then
		wget --show-progress --tries=3 -q -O "$path" "$download_url"
	elif command -v curl &>/dev/null; then
		curl -fSL --progress-bar -o "$path" "$download_url"
	else
		printf "Error: Neither wget nor curl is available to download files, please install one of them and try again.\n"
		exit 1
	fi
}

printf "Downloading Godots...\n"
try_download "$GODOTS_DOWNLOAD_URL" "$GODOTS_TMP_DIR"

printf "\nExtracting Godots...\n"
if command -v python3 &>/dev/null; then
	python3 -c "
import zipfile
import os
import sys

zip_path = '$GODOTS_TMP_DIR'
extract_dir = os.path.expanduser('$GODOTS_INSTALL_DIR')

# Create target directory if it doesn't exist
os.makedirs(extract_dir, exist_ok=True)

# Extract the zip file
with zipfile.ZipFile(zip_path, 'r') as zip_ref:
    zip_ref.extractall(extract_dir)

print('Extraction completed successfully!')
"
elif command -v unzip &>/dev/null; then
	mkdir -p "$GODOTS_INSTALL_DIR"
	unzip -o "$GODOTS_TMP_DIR" -d "$GODOTS_INSTALL_DIR"
	printf "Extraction completed successfully!\n"
else
	printf "Error: Neither python3 nor unzip is available to extract the zip file, please install one of them and try again.\n"
	exit 1
fi

chmod +x "$GODOTS_INSTALL_DIR/"*
ln -sf "$GODOTS_BIN_PATH" "$HOME/.local/bin/godots"

printf "\nDownloading icon...\n"
try_download "$ICON_DOWNLOAD_URL" "$ICON_PATH"

printf "\nCreating desktop entry..."
mkdir -p ~/.local/share/applications

cat <<EOF >~/.local/share/applications/godots.desktop
[Desktop Entry]
Name=Godots
GenericName=Libre game engine version manager
Comment=Ultimate go-to hub for managing your Godot versions and projects!
Exec=$GODOTS_BIN_PATH %U
Icon=$ICON_PATH
PrefersNonDefaultGPU=true
Terminal=false
Type=Application
Categories=Development;IDE;
StartupWMClass=Godot
EOF

if command -v update-desktop-database &>/dev/null; then
	update-desktop-database -q
fi

if command gtk-upate-icon-cache &>/dev/null; then
	gtk-update-icon-cache
fi

if command -v kbuildsycoca5 &>/dev/null; then
	kbuildsycoca5 --noincremental &>/dev/null
fi

printf "\nInstallation completed successfully!\n"
