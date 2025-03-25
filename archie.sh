#!/bin/bash

set -e  # Exit on error

# 1️⃣ Define variables
ISO_URL="https://mirror.rackspace.com/archlinux/iso/latest/archlinux-x86_64.iso"
ISO_FILE="$HOME/archlinux.iso"
MOUNT_DIR="/mnt/archiso"
BUILD_DIR="$HOME/arch-build"
CUSTOM_ISO_DIR="$HOME/myarchiso"
ARCHISO_WORKDIR="/tmp/archiso-tmp"
ARCHISO_OUTPUT="/tmp/archlinux-custom.iso"

# 2️⃣ Install necessary tools
echo "Installing required packages..."
sudo pacman -Syu --noconfirm git base-devel devtools archiso wget

# 3️⃣ Download the official Arch Linux ISO
echo "Downloading Arch Linux ISO..."
wget -O "$ISO_FILE" "$ISO_URL"

# 4️⃣ Mount the ISO and extract package list
echo "Mounting ISO and extracting package list..."
mkdir -p "$MOUNT_DIR"
sudo mount -o loop "$ISO_FILE" "$MOUNT_DIR"

bsdtar -xf "$MOUNT_DIR/airootfs.sfs" -C /mnt
ls /mnt/var/lib/pacman/local/ | cut -d '-' -f 1 | sort -u > "$HOME/official-packages.txt"

echo "Extracted package list saved to $HOME/official-packages.txt"
cat "$HOME/official-packages.txt"

# 5️⃣ Download and compile packages
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
done < "$HOME/official-packages.txt"

# 6️⃣ Set up custom Arch ISO
echo "Setting up custom Arch Linux ISO..."
mkdir -p "$CUSTOM_ISO_DIR"
cp -r /usr/share/archiso/configs/releng/* "$CUSTOM_ISO_DIR"
cd "$CUSTOM_ISO_DIR"

# 7️⃣ Modify packages list to include compiled packages
echo "Updating package list for custom ISO..."
rm packages.x86_64
find "$BUILD_DIR" -name "*.pkg.tar.zst" -exec basename {} \; > packages.x86_64

# 8️⃣ Build the ISO
echo "Building the custom Arch Linux ISO..."
mkarchiso -v -w "$ARCHISO_WORKDIR" -o "$ARCHISO_OUTPUT" "$CUSTOM_ISO_DIR"

echo "✅ Custom Arch Linux ISO is ready at: $ARCHISO_OUTPUT"

# 9️⃣ Cleanup
echo "Unmounting ISO..."
sudo umount "$MOUNT_DIR"
rm -rf "$MOUNT_DIR"

echo "🎉 Done! You can now test or burn your ISO."
