#!/bin/bash

set -e  # Exit on error

# 1️⃣ Define variables
BUILD_DIR="$HOME/arch-build"
CUSTOM_ISO_DIR="$HOME/myarchiso"
ARCHISO_WORKDIR="/tmp/archiso-tmp"
ARCHISO_OUTPUT="/tmp/archlinux-custom.iso"

# 2️⃣ Install necessary tools
echo "Installing required packages..."
sudo pacman -Syu --noconfirm git base-devel devtools archiso

# 3️⃣ Get the list of currently installed packages
echo "Extracting list of installed packages..."
pacman -Qq | sort -u > "$HOME/current-packages.txt"
echo "Package list saved to $HOME/current-packages.txt"

# 4️⃣ Download and compile packages
echo "Downloading and compiling packages..."
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

while read package; do
    if git clone --depth=1 "https://gitlab.archlinux.org/archlinux/packaging/packages/$package.git"; then
        cd "$package"
        makepkg -s --noconfirm || echo "Failed to build $package"
        cd ..
    else
        echo "Skipping $package (not found in repository)"
    fi
done < "$HOME/current-packages.txt"

# 5️⃣ Set up custom Arch ISO
echo "Setting up custom Arch Linux ISO..."
mkdir -p "$CUSTOM_ISO_DIR"
cp -r /usr/share/archiso/configs/releng/* "$CUSTOM_ISO_DIR"
cd "$CUSTOM_ISO_DIR"

# 6️⃣ Modify packages list to include compiled packages
echo "Updating package list for custom ISO..."
rm packages.x86_64
find "$BUILD_DIR" -name "*.pkg.tar.zst" -exec basename {} \; > packages.x86_64

# 7️⃣ Build the ISO
echo "Building the custom Arch Linux ISO..."
mkarchiso -v -w "$ARCHISO_WORKDIR" -o "$ARCHISO_OUTPUT" "$CUSTOM_ISO_DIR"

echo "✅ Custom Arch Linux ISO is ready at: $ARCHISO_OUTPUT"

echo "🎉 Done! You can now test or burn your ISO."
