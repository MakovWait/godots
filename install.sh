#!/usr/bin/env bash

DOWNLOAD_URL="https://github.com/MakovWait/godots/releases/latest/download/LinuxX11.zip"

# Download the latest version of Godots
wget -O /tmp/godots.zip $DOWNLOAD_URL || exit

# Unzip the downloaded file to ~/.local/godots.app/ and replace if exists
unzip -o /tmp/godots.zip -d ~/.local/godots.app/ || exit

# download Icon
wget -O ~/.local/godots.app/icon.svg https://github.com/MakovWait/godots/raw/main/icon.svg || exit

# Create a desktop entry for Godots
cat <<EOF > ~/.local/share/applications/godots.desktop
[Desktop Entry]
Name=Godots
GenericName=Libre game engine version manager
Comment=Ultimate go-to hub for managing your Godot versions and projects!
Exec=$HOME/.local/godots.app/Godots.x86_64
Icon=$HOME/.local/godots.app/icon.svg
PrefersNonDefaultGPU=true
Terminal=false
Type=Application
Categories=Development;IDE;
StartupWMClass=Godot
EOF

echo "Installation completed successfully!"
