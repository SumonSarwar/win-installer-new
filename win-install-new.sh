#!/bin/bash

# Windows Installation Script (Supports both /dev/sda and /dev/vda)
WINDOWS_IMAGE_URL="https://pub-9a673eab24524f43a0e6774c2e3ec306.r2.dev/Windows2022.gz"

# Ensure running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

# Detect Primary Disk (/dev/sda or /dev/vda)
if [ -b /dev/vda ]; then
    DISK="/dev/vda"
elif [ -b /dev/sda ]; then
    DISK="/dev/sda"
else
    echo "No valid disk found! Exiting..."
    exit 1
fi

echo "Using disk: $DISK"

# Update & Install Required Packages
echo "Updating system and installing necessary tools..."
apt update && apt install -y wget curl gunzip gdisk grub-efi-amd64 dosfstools parted coreutils

# Download Windows Image
echo "Downloading Windows image..."
wget -O /root/windows2022.gz "$WINDOWS_IMAGE_URL" || curl -o /root/windows2022.gz "$WINDOWS_IMAGE_URL"

# Check if file downloaded correctly
if [ ! -f "/root/windows2022.gz" ]; then
    echo "Download failed! Exiting..."
    exit 1
fi

# Extract Image
echo "Extracting Windows image..."
gunzip -c /root/windows2022.gz > /root/windows2022.img

# Check if extraction was successful
if [ ! -f "/root/windows2022.img" ]; then
    echo "Extraction failed! Exiting..."
    exit 1
fi

# Unmount Disk if mounted
umount ${DISK}* 2>/dev/null

# Check & Repair Disk (Fix Partition Issues)
echo "Checking & repairing disk..."
fsck -y $DISK

# Write Image to Disk
echo "Writing Windows image to disk ($DISK)..."
dd if=/root/windows2022.img of=$DISK bs=1M status=progress oflag=direct conv=fsync

# Ensure disk write is completed
sync

echo "Fixing partition table..."
echo -e "w" | gdisk $DISK

# Install GRUB and Configure Boot
echo "Installing and configuring GRUB..."
grub-install --target=i386-pc --recheck $DISK
grub-mkconfig -o /boot/grub/grub.cfg

# Final Sync to ensure all writes are completed
sync

# Reboot to Windows
echo "Installation completed! Rebooting to Windows..."
sleep 5
reboot -f
