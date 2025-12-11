#!/bin/bash
# ISO Generation Script for eOS
# This script generates an offline ISO of your eOS image

echo "eOS ISO Generation Tool"
echo "======================="
echo ""

# Check if we're running on Fedora Atomic
if [[ ! -f /etc/os-release ]]; then
    echo "Error: This script should be run on a Fedora Atomic system"
    exit 1
fi

if ! grep -q "Fedora" /etc/os-release; then
    echo "Error: This script should be run on a Fedora system"
    exit 1
fi

# Check for required tools
REQUIRED_TOOLS=("rpm-ostree" "lorax" "livecd-tools" "isomd5sum")
MISSING_TOOLS=()

for tool in "${REQUIRED_TOOLS[@]}"; do
    if ! command -v "$tool" >/dev/null; then
        MISSING_TOOLS+=("$tool")
    fi
done

if [[ ${#MISSING_TOOLS[@]} -gt 0 ]]; then
    echo "Missing required tools: ${MISSING_TOOLS[*]}"
    echo "Installing them now..."
    sudo dnf install -y "${MISSING_TOOLS[@]}"
fi

echo "1. Checking current deployment..."
CURRENT_DEPLOYMENT=$(rpm-ostree status --json | jq -r '.deployments[0].checksum')
echo "   Current deployment: $CURRENT_DEPLOYMENT"

echo ""
echo "2. Setting up ISO generation environment..."
WORK_DIR="/tmp/eos-iso-build"
ISO_DIR="$WORK_DIR/iso"
OUTPUT_DIR="$HOME/eos-isos"

rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR"
mkdir -p "$ISO_DIR"
mkdir -p "$OUTPUT_DIR"

echo ""
echo "3. Creating kickstart file..."
cat > "$WORK_DIR/kickstart.ks" << 'EOF'
# eOS Kickstart File
# Generated ISO installation configuration

# System configuration
lang en_US.UTF-8
keyboard us
timezone --utc America/New_York

# Network configuration
network --onboot yes --device eth0 --bootproto dhcp

# Root password (will be disabled for atomic)
rootpw --lock

# System authorization
auth --enableshadow --passalgo=sha512

# SELinux configuration
selinux --enforcing

# Firewall configuration
firewall --enabled

# Bootloader configuration
bootloader --timeout=1 --append="rhgb quiet"

# Partitioning
clearpart --all --initlabel
part /boot/efi --fstype="efi" --size=500
part /boot --fstype="xfs" --size=1000
part / --fstype="btrfs" --size=1 --grow

# Package selection (minimal for atomic)
%packages
@core
%end

# Post-installation script
%post --log=/root/ks-post.log
# Set up rpm-ostree for eOS
echo "Setting up rpm-ostree for eOS..."
rpm-ostree rebase ostree-image-signed:docker://ghcr.io/evanriley/eos:latest

# Enable systemd services
systemctl enable niri-session.service
systemctl --user enable swww.service

# Set up user environment
USER_NAME="evan"
useradd -m -G wheel "$USER_NAME"
echo "$USER_NAME:password" | chpasswd

# Set default shell to fish
chsh -s /usr/bin/fish "$USER_NAME"

# Copy dotfiles setup script
cp /usr/local/bin/setup-dotfiles.sh /home/$USER_NAME/
chown $USER_NAME:$USER_NAME /home/$USER_NAME/setup-dotfiles.sh
chmod +x /home/$USER_NAME/setup-dotfiles.sh

# Set up autologin for live session
mkdir -p /etc/systemd/system/getty@tty1.service.d/
cat > /etc/systemd/system/getty@tty1.service.d/override.conf << 'EOL'
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $USER_NAME --noclear %I $TERM
EOL

%end

# Reboot after installation
reboot
EOF

echo ""
echo "4. Building ISO with lorax..."

# Create lorax configuration
cat > "$WORK_DIR/lorax-config.toml" << 'EOF'
[lorax]
product = "eOS"
version = "42"
release = "$(date +%Y%m%d)"
variant = "Silverblue"
iso_name = "eos-$(date +%Y%m%d).iso"

[packages]
# Additional packages to include in the ISO
additional_packages = [
    "rpm-ostree",
    "lorax",
    "livecd-tools",
    "isomd5sum",
    "jq"
]
EOF

echo ""
echo "5. Generating ISO (this may take a while)..."

# Use lorax to create the ISO
sudo lorax --product=eOS --version=42 --release=$(date +%Y%m%d) \
    --isfinal --buildarch=x86_64 \
    --kickstart="$WORK_DIR/kickstart.ks" \
    --output="$ISO_DIR" \
    "$WORK_DIR/lorax-config.toml"

echo ""
echo "6. Creating checksums..."
pushd "$ISO_DIR" >/dev/null
isomd5sum "eos-$(date +%Y%m%d).iso"
popd >/dev/null

echo ""
echo "7. Moving ISO to output directory..."
mv "$ISO_DIR/eos-$(date +%Y%m%d).iso" "$OUTPUT_DIR/"
mv "$ISO_DIR/eos-$(date +%Y%m%d).iso.md5" "$OUTPUT_DIR/"

echo ""
echo "ISO generation complete!"
echo ""
echo "Your ISO is available at:"
echo "  $OUTPUT_DIR/eos-$(date +%Y%m%d).iso"
echo ""
echo "MD5 checksum:"
echo "  $OUTPUT_DIR/eos-$(date +%Y%m%d).iso.md5"
echo ""
echo "You can now:"
echo "1. Burn the ISO to a USB drive using dd or balenaEtcher"
echo "2. Boot from the USB drive to install eOS"
echo "3. The installation will automatically set up rpm-ostree to use eOS"
echo ""
echo "Note: The ISO includes a basic setup. After installation, you should:"
echo "1. Run the dotfiles migration script: setup-dotfiles.sh"
echo "2. Migrate your existing configurations"
echo "3. Customize your environment"

# Cleanup
rm -rf "$WORK_DIR"