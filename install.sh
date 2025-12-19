#!/bin/env bash

GODOTS_DOWNLOAD_URL="https://github.com/MakovWait/godots/releases/latest/download/LinuxX11.zip"
GODOTS_TMP_DIR="/tmp/godots"

GODOTS_CHECKSUM_URL="https://github.com/MakovWait/godots/releases/latest/download/SHA512-SUMS.txt"

if [[ -z "$XDG_DATA_HOME" ]]; then
	GODOTS_INSTALL_DIR="$XDG_DATA_HOME/godots"
else
	GODOTS_INSTALL_DIR="$HOME/.local/share/godots"
fi

GODOTS_BIN_PATH="$GODOTS_INSTALL_DIR/Godots.x86_64"

ICON_DOWNLOAD_URL="https://raw.githubusercontent.com/MakovWait/godots/refs/heads/main/icon.svg"

try_download() {
	download_url=$1
	path=$2
	if command -v wget &>/dev/null; then
		wget --show-progress --tries=3 -q -P "$path" "$download_url" || {
			printf "Error: Download failed.\n"
			exit 1
		}
	elif command -v curl &>/dev/null; then
		curl -fSL --progress-bar -O --output-dir "$path" "$download_url" || {
			printf "Error: Download failed.\n"
			exit 1
		}
	else
		printf "Error: Neither wget nor curl is available to download files, please install one of them and try again.\n"
		exit 1
	fi
}

rm -rf "$GODOTS_TMP_DIR" || {
	printf "Error: Failed to clean up temporary directory.\n"
	exit 1
}

mkdir -p "$GODOTS_TMP_DIR" || {
	printf "Error: Failed to create temporary directory.\n"
	exit 1
}

cd "$GODOTS_TMP_DIR" || {
	printf "Error: Failed to access temporary directory.\n"
	exit 1
}

printf "Downloading Godots...\n"
try_download "$GODOTS_DOWNLOAD_URL" "$GODOTS_TMP_DIR"

prompt_continue=0

if command -v sha512sum &>/dev/null; then
	printf "\nDownloading checksum...\n"
	try_download "$GODOTS_CHECKSUM_URL" "$GODOTS_TMP_DIR"

	printf "\nVerifying checksum...\n"
	sha512sum --check --ignore-missing "$GODOTS_TMP_DIR/SHA512-SUMS.txt" || prompt_continue=1

else
	# I think it is part of coreutils, so it should be available on most systems. But just in case.
	printf "Error: sha512sum is not available to verify the checksum. Skipping.\n"
	prompt_continue=1
fi

if [[ $prompt_continue -eq 1 ]]; then
	read -r -p "Checksum verification failed or was skipped. Do you want to continue the installation? (y/N): " choice
	case "$choice" in
	y | Y)
		printf "Continuing installation...\n"
		;;
	*)
		printf "Installation aborted.\n"
		exit 1
		;;
	esac
fi

# Create installation directory
mkdir -p "$GODOTS_INSTALL_DIR" || {
	printf "Error: Failed to create installation directory.\n"
	exit 1
}

printf "\nExtracting Godots...\n"
if command -v python3 &>/dev/null; then
	python3 -c "
import zipfile
import os
import sys

zip_path = '$GODOTS_TMP_DIR/LinuxX11.zip'
extract_dir = os.path.expanduser('$GODOTS_INSTALL_DIR')

# Create target directory if it doesn't exist
os.makedirs(extract_dir, exist_ok=True)

# Extract the zip file
with zipfile.ZipFile(zip_path, 'r') as zip_ref:
    zip_ref.extractall(extract_dir)

print('Extraction completed successfully!')
" || {
		printf "Error: Extraction failed.\n"
		exit 1
	}
elif command -v unzip &>/dev/null; then
	unzip -o "$GODOTS_TMP_DIR/LinuxX11.zip" -d "$GODOTS_INSTALL_DIR" || {
		printf "Error: Extraction failed.\n"
		exit 1
	}
	printf "Extraction completed successfully!\n"
else
	printf "Error: Neither python3 nor unzip is available to extract the zip file, please install one of them and try again.\n"
	exit 1
fi

chmod +x "$GODOTS_INSTALL_DIR/"* || {
	printf "Error: Failed to set executable permissions.\n"
	exit 1
}

mkdir -p "$HOME/.local/bin" || {
	printf "Error: Failed to create ~/.local/bin directory.\n"
	exit 1
}

ln -sf "$GODOTS_BIN_PATH" "$HOME/.local/bin/godots" || {
	printf "Error: Failed to create symlink in ~/.local/bin.\n"
	exit 1
}

printf "\nDownloading icon...\n"
try_download "$ICON_DOWNLOAD_URL" "$GODOTS_INSTALL_DIR"

printf "\nCreating desktop entry..."
mkdir -p ~/.local/share/applications || {
	printf "Error: Failed to create applications directory.\n"
	exit 1
}

cat <<EOF >~/.local/share/applications/godots.desktop
[Desktop Entry]
Name=Godots
GenericName=Libre game engine version manager
Comment=Ultimate go-to hub for managing your Godot versions and projects!
Exec=$GODOTS_BIN_PATH %U
Icon=$GODOTS_INSTALL_DIR/icon.svg
PrefersNonDefaultGPU=true
Terminal=false
Type=Application
Categories=Development;IDE;
StartupWMClass=Godot
EOF

if [[ ! -f ~/.local/share/applications/godots.desktop ]]; then
	printf "Error: Failed to create desktop entry.\n"
	exit 1
fi

if command -v update-desktop-database &>/dev/null; then
	update-desktop-database -q
fi

if command -v gtk-update-icon-cache &>/dev/null; then
	gtk-update-icon-cache
fi

if command -v kbuildsycoca5 &>/dev/null; then
	kbuildsycoca5 --noincremental &>/dev/null
fi

printf "\nInstallation completed successfully!\n"
