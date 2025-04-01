#!/bin/env bash

DOWNLOAD_URL="https://github.com/MakovWait/godots/releases/latest/download/LinuxX11.zip"

# Download the latest version of Godots
wget -O /tmp/godots.zip $DOWNLOAD_URL

# Unzip the downloaded file to ~/.local/godots.app/
unzip /tmp/godots.zip -d ~/.local/godots.app/

# download Icon
wget -O ~/.local/godots.app/icon.svg https://github.com/MakovWait/godots/raw/master/icon.svg

# Create a desktop entry for Godots
cat <<EOF > ~/.local/share/applications/godots.desktop
[Desktop Entry]
Name=Godots
GenericName=Libre game engine version manager
Comment=Ultimate go-to hub for managing your Godot versions and projects!
Exec=~/.local/godots.app/godots
Icon=~/.local/godots.app/icon.svg
PrefersNonDefaultGPU=true
Terminal=false
Type=Application
Categories=Development;IDE;
StartupWMClass=Godot
EOF

echo "Installation completed successfully!"
