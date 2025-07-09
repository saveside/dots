#!/usr/bin/env bash
set -e

# ┌────────────────────┐
# │  Save's Dots Setup │
# └────────────────────┘

echo "┌────────────────────┐"
echo "│  Save's Dots Setup │"
echo "└────────────────────┘"
echo

# ── Choose dotfiles repo ───────────────────────────────
echo "Choices:"
echo "1.) Save's Dots (default)"
echo "2.) Jomo's Dots (for testing and other reasons)"
read -rp "Enter choice [1/2]: " choice

case "$choice" in
    2)
        gh_repo_url="https://github.com/jomo-dev/dots"
        ;;
    1|"")
        gh_repo_url="https://github.com/saveside/dots"
        ;;
    *)
        echo "❌ Invalid choice. Defaulting to Save's Dots."
        gh_repo_url="https://github.com/saveside/dots"
        ;;
esac

# ── Check if GitHub repo is reachable ──────────────────
echo
echo "🌐 Checking GitHub repo URL..."
gh_status=$(wget --server-response --spider "$gh_repo_url" 2>&1 | awk '/HTTP\// {print $2; exit}')
if [ "$gh_status" -eq 200 ]; then
    echo "✅ GitHub repo is reachable."
else
    echo -e "❌ GitHub repo is NOT reachable :( \nExiting."
    exit 1
fi

# ── Check if system is Arch-based ──────────────────────
id_like=$(grep '^ID_LIKE=' /etc/os-release | head -n1 | sed 's/^ID_LIKE=//; s/"//g')

if [[ "$id_like" == *arch* ]]; then
    echo "✅ Distribution is Arch-based. Continuing setup..."
else
    echo "❌ Distribution is not Arch-based. This script is intended for Arch-based systems only."
    exit 1
fi

# ── Detect or install AUR helper ───────────────────────
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
    sudo pacman -S --needed base-devel git

    echo "⬇️  Cloning 'yay' from the AUR..."
    cd "$(mktemp -d)" || exit
    git clone https://aur.archlinux.org/yay.git
    cd yay || exit

    echo "⚙️  Building and installing 'yay'..."
    makepkg -si

    aur_helper="yay"
    echo "✅ AUR helper 'yay' installed successfully."
fi

# ── Install packages from GitHub list ──────────────────
echo "⬇️  Downloading package list from GitHub..."
cd "$(mktemp -d)" || exit
wget https://raw.githubusercontent.com/saveside/dots/refs/heads/main/pkgs

echo "📦 Installing packages using $aur_helper..."
$aur_helper -S --needed - < pkgs

# ── Set up chezmoi with selected repo ──────────────────
echo "🎯 Setting up dotfiles with chezmoi..."
chezmoi init "$gh_repo_url"
chezmoi apply -v

# ── Download and install fonts ─────────────────────────
echo "🔤 Downloading fonts..."

sf_pro_url="https://files.savew.dev/sf-pro.zip"
sf_pro_fallback="https://files.xeome.dev/sf-pro.zip"

echo "🌐 Checking SF Pro font URL..."
status=$(wget --server-response --spider "$sf_pro_url" 2>&1 | awk '/HTTP\// {print $2; exit}')
if [ "$status" -eq 200 ]; then
    echo "✅ SF Pro font URL is reachable. Downloading..."
    wget "$sf_pro_url"
else
    echo "⚠️  SF Pro main URL failed. Checking fallback URL..."
    fallback_status=$(wget --server-response --spider "$sf_pro_fallback" 2>&1 | awk '/HTTP\// {print $2; exit}')
    if [ "$fallback_status" -eq 200 ]; then
        echo "✅ Fallback URL is reachable. Downloading fallback font..."
        wget "$sf_pro_fallback"
    else
        echo "❌ Both main and fallback URLs are unreachable. Exiting."
        exit 1
    fi
fi

# ── Extract and refresh fonts ──────────────────────────
echo "🗂️  Extracting fonts to ~/.fonts..."
mkdir -p ~/.fonts
bsdtar -xf sf-pro.zip -C ~/.fonts

echo "🌀 Refreshing font cache..."
fc-cache -frv

echo "🧹 Cleaning up downloaded font archives..."
rm "sf-pro.zip"

# ── Done ───────────────────────────────────────────────
echo "✅ All done! jomolayana..."
