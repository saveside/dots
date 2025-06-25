#!/bin/bash

. /etc/os-release

# Check if the distribution is Arch-based
if [[ "$ID_LIKE" == "arch" ]]; then
    echo "✅ Distribution is Arch-based. Continuing setup..."
else
    echo "❌ Distribution is not Arch-based. This script is intended for Arch-based systems only."
    exit 1
fi

# Detect available AUR helper
echo "🔍 Checking for AUR helper (yay or paru)..."
if command -v yay &> /dev/null; then
    echo "✅ AUR helper 'yay' detected."
    aur_helper="yay"
elif command -v paru &> /dev/null; then
    echo "✅ AUR helper 'paru' detected."
    aur_helper="paru"
else
    echo "⚠️  No AUR helper found on the system."
    echo "📦 Installing prerequisites: base-devel and git..."
    pacman -S --needed base-devel git

    echo "⬇️  Cloning 'yay' from the AUR..."
    cd "$(mktemp -d)" || exit
    git clone https://aur.archlinux.org/yay.git
    cd yay || exit

    echo "⚙️  Building and installing 'yay'..."
    makepkg -si

    aur_helper="yay"
    echo "✅ AUR helper 'yay' installed successfully."
fi

# Install packages from remote list
echo "⬇️  Downloading package list from GitHub..."
cd "$(mktemp -d)" || exit
wget https://raw.githubusercontent.com/saveside/dots/refs/heads/main/pkgs

echo "📦 Installing packages using $aur_helper..."
$aur_helper -S --needed - < pkgs

# Initialize and apply chezmoi dotfiles
echo "🎯 Setting up dotfiles with chezmoi..."
chezmoi init https://github.com/saveside/dots
chezmoi apply -v

# Download fonts (SF Pro with fallback, and Monaspace)
echo "🔤 Downloading fonts..."

sf_pro_url="https://files.savew.dev/sf-pro.zip"
sf_pro_fallback="https://files.xeome.dev/sf-pro.zip"
monaspace_url="https://github.com/githubnext/monaspace/releases/download/v1.000/monaspace-v1.000.zip"

echo "🌐 Checking SF Pro font URL..."
status=$(curl -o /dev/null -s -w "%{http_code}" "$sf_pro_url")
if [ "$status" -eq 200 ]; then
    echo "✅ SF Pro font URL is reachable. Downloading..."
    wget "$sf_pro_url"
else
    echo "⚠️  SF Pro main URL failed. Using fallback..."
    wget "$sf_pro_fallback"
fi

echo "🌐 Checking Monaspace font URL..."
status=$(curl -o /dev/null -s -w "%{http_code}" "$monaspace_url")
if [ "$status" -eq 200 ]; then
    echo "✅ Monaspace font URL is reachable. Downloading..."
    wget "$monaspace_url"
else
    echo "❌ Failed to download Monaspace font."
fi

# Install fonts
echo "🗂️  Extracting fonts to ~/.fonts..."
mkdir -p ~/.fonts
unzip -q sf-pro.zip -d ~/.fonts
unzip -q monaspace-v1.000.zip -d ~/.fonts

echo "🌀 Refreshing font cache..."
fc-cache -frv

echo "🧹 Cleaning up downloaded font archives..."
rm -rf "sf-pro.zip" "monaspace-v1.000.zip"

echo "✅ All done! jomolayana..."

