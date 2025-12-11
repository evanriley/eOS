#!/bin/bash
# Dotfiles migration script for eOS
# This script helps migrate dotfiles from an existing setup to the new atomic Fedora installation

echo "eOS Dotfiles Migration Tool"
echo "==========================="
echo ""

# Check if we're running as the user
if [[ "$EUID" -eq 0 ]]; then
    echo "This script should be run as your regular user, not root."
    exit 1
fi

CONFIG_DIR="$HOME/.config"
DOTFILES_REPO="$HOME/.dotfiles"
BACKUP_DIR="$HOME/dotfiles-backup-$(date +%Y%m%d-%H%M%S)"

echo "1. Checking for existing dotfiles..."
if [[ -d "$DOTFILES_REPO" ]]; then
    echo "   Found existing dotfiles repository at $DOTFILES_REPO"
else
    echo "   No existing dotfiles repository found"
fi

echo ""
echo "2. Creating backup of current configurations..."
mkdir -p "$BACKUP_DIR"
echo "   Backup directory created: $BACKUP_DIR"

# List of important config directories to backup
IMPORTANT_CONFIGS=(
    "niri"
    "foot"
    "fish"
    "starship.toml"
    "rofi"
    "btop"
    "gtk-3.0"
    "gtk-4.0"
    "swww"
    "systemd/user"
)

for config in "${IMPORTANT_CONFIGS[@]}"; do
    if [[ -e "$CONFIG_DIR/$config" ]]; then
        echo "   Backing up $config..."
        cp -r "$CONFIG_DIR/$config" "$BACKUP_DIR/"
    fi
done

echo ""
echo "3. Setting up dotfiles repository..."
if [[ ! -d "$DOTFILES_REPO" ]]; then
    echo "   Initializing new dotfiles repository..."
    git init --bare "$DOTFILES_REPO"
    
    # Create alias for easy dotfiles management
    if ! grep -q "dots()" "$HOME/.bashrc" 2>/dev/null; then
        echo "   Adding 'dots' alias to .bashrc"
        echo "" >> "$HOME/.bashrc"
        echo "# Dotfiles management" >> "$HOME/.bashrc"
        echo "dots() {" >> "$HOME/.bashrc"
        echo "    git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME "$@"" >> "$HOME/.bashrc"
        echo "}" >> "$HOME/.bashrc"
    fi
    
    if ! grep -q "dots()" "$HOME/.config/fish/config.fish" 2>/dev/null; then
        echo "   Adding 'dots' alias to fish config"
        echo "" >> "$HOME/.config/fish/config.fish"
        echo "# Dotfiles management" >> "$HOME/.config/fish/config.fish"
        echo "function dots" >> "$HOME/.config/fish/config.fish"
        echo "    git --git-dir=\$HOME/.dotfiles/ --work-tree=\$HOME \$argv" >> "$HOME/.config/fish/config.fish"
        echo "end" >> "$HOME/.config/fish/config.fish"
    fi
else
    echo "   Dotfiles repository already exists"
fi

echo ""
echo "4. Setting up basic configurations..."

# Create basic config directories
mkdir -p "$CONFIG_DIR/niri"
mkdir -p "$CONFIG_DIR/foot"
mkdir -p "$CONFIG_DIR/fish"
mkdir -p "$CONFIG_DIR/rofi"
mkdir -p "$HOME/.local/bin"
mkdir -p "$CONFIG_DIR/systemd/user"

echo ""
echo "5. Creating basic Niri configuration..."
cat > "$CONFIG_DIR/niri/config.kdl" << 'EOF'
# Basic Niri configuration - customize this further
input {
    keyboard {
        xkb {
            layout "us"
        }
        numlock
    }
    mouse {
        accel-speed 0.0
        accel-profile "flat"
    }
    touchpad {
        tap
        natural-scroll
    }
    focus-follows-mouse max-scroll-amount="25%"
    workspace-auto-back-and-forth
    warp-mouse-to-focus
}

workspace "web" {}
workspace "social" {}
workspace "games" {}
workspace "files" {}
workspace "mail" {}
workspace "system" {}

output "DP-1" {
    mode "5120x1440@119.979"
    scale 1
    transform "normal"
    variable-refresh-rate
}

cursor {
    xcursor-theme "Bibata-Original-Classic"
    hide-after-inactive-ms 3000
}

binds {
    MOD+SHIFT+SLASH {
        show-hotkey-overlay
    }
    MOD+RETURN hotkey-overlay-title="Open Terminal: foot" {
        spawn "foot"
    }
    Mod+SPACE hotkey-overlay-title="Run an Application: rofi" {
        spawn "appdrawer"
    }
    Mod+P {
        spawn "powermenu"
    }
    MOD+ALT+L hotkey-overlay-title="Lock Screen: swaylock" {
        spawn-sh "swaylock"
    }
    MOD+Q {
        close-window
    }
    Mod+O repeat=false {
        toggle-overview
    }
    MOD+E hotkey-overlay-title="File Manager: Nautilus" {
        spawn-sh "nautilus"
    }
}

spawn-sh-at-startup "/usr/lib/polkit-gnome-authentication-agent-1 &"
spawn-sh-at-startup "swww img /usr/share/backgrounds/default.png"

prefer-no-csd
screenshot-path "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png"

layout {
    gaps 6
    center-focused-column "never"
    always-center-single-column
    preset-column-widths {
        proportion 0.25
        proportion 0.5
        proportion 0.75
    }
    default-column-width {
        proportion 0.5
    }
    focus-ring {
        off
    }
    border {
        off
    }
    shadow {
        on
        softness 30
        spread 5
        offset x=0 y=5
        color "#0007"
    }
    background-color "transparent"
}

animations {
    workspace-switch {
        spring damping-ratio=1.0 stiffness=1000 epsilon=0.0001
    }
    window-open {
        duration-ms 200
        curve "ease-out-quad"
    }
    window-close {
        duration-ms 200
        curve "ease-out-cubic"
    }
}

environment {
    DISPLAY ":1"
    ELECTRON_OZONE_PLATFORM_HINT "auto"
    QT_QPA_PLATFORM "wayland"
    QT_WAYLAND_DISABLE_WINDOWDECORATION "1"
    XDG_SESSION_TYPE "wayland"
    XDG_CURRENT_DESKTOP "niri"
    GTK_THEME "Adwaita:dark"
    QT_QPA_PLATFORMTHEME "gtk3"
}

hotkey-overlay {
    skip-at-startup
}
EOF

echo ""
echo "6. Creating basic Foot terminal configuration..."
cat > "$CONFIG_DIR/foot/foot.ini" << 'EOF'
[main]
shell=fish
login-shell=no
font=Fira Code:size=12
pad=8x8

[cursor]
style=block
blink=no

[mouse]
hide-when-typing=yes

[colors]
alpha=1.0
foreground=c5c9c7
background=090e13
regular0=090e13
regular1=c4746e
regular2=8a9a7b
regular3=c4b28a
regular4=8ba4b0
regular5=a292a3
regular6=8ea4a2
regular7=a4a7a4
bright0=5c6066
bright1=e46876
bright2=87a987
bright3=e6c384
bright4=7fb4ca
bright5=938aa9
bright6=7aa89f
bright7=c5c9c7
selection-foreground=c5c9c7
selection-background=22262d

[scrollback]
lines=10000
multiplier=3.0
indicator-position=relative
EOF

echo ""
echo "7. Creating basic Fish shell configuration..."
cat > "$CONFIG_DIR/fish/config.fish" << 'EOF'
set -g fish_greeting
set -gx EDITOR nvim
set -gx XDG_CONFIG_HOME "$HOME/.config"
set -gx PATH ~/bin ~/.local/bin ~/go/bin ~/.config/emacs/bin ~/.cargo/bin $PATH

# Aliases
alias dots 'git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
alias vim nvim
alias cd.. 'cd ..'
alias .. 'cd ..'
alias ... 'cd ../../'
alias .... 'cd ../../../'
alias ls eza
alias cat bat
alias du dust

# Initialize tools
if command -v zoxide >/dev/null
    zoxide init fish | source
end

if command -v mise >/dev/null
    mise activate fish | source
end
EOF

echo ""
echo "8. Creating basic utility scripts..."

# Create basic appdrawer script
cat > "$HOME/.local/bin/appdrawer" << 'EOF'
#!/usr/bin/env bash
rofi -show drun -config "$HOME/.config/rofi/appdrawer.rasi"
EOF

# Create basic powermenu script
cat > "$HOME/.local/bin/powermenu" << 'EOF'
#!/usr/bin/env bash

# Menu options
shutdown="$(printf '\uf16f')"
reboot="$(printf '\ue5d5')"
suspend="$(printf '\uef44')"
logout="$(printf '\ue9ba')"

# Give options to rofi and save choice
chosen="$(echo -e "$shutdown\n$reboot\n$suspend\n$logout" | rofi -dmenu -config "$HOME/.config/rofi/powermenu.rasi")"

case "$chosen" in
  "$shutdown")
    poweroff
    ;;
  "$reboot")
    reboot
    ;;
  "$suspend")
    systemctl suspend
    ;;
  "$logout")
    niri msg action quit
    ;;
  *)
    exit 0
    ;;
esac
EOF

# Make scripts executable
chmod +x "$HOME/.local/bin/appdrawer"
chmod +x "$HOME/.local/bin/powermenu"

echo ""
echo "9. Setting up systemd user services..."

# Create basic swww service
cat > "$CONFIG_DIR/systemd/user/swww.service" << 'EOF'
[Unit]
Description=Wallpaper daemon
PartOf=graphical-session.target
After=graphical-session.target

[Service]
ExecStart=/usr/bin/swww-daemon
Restart=on-failure

[Install]
WantedBy=graphical-session.target
EOF

# Create basic overview listener service (placeholder)
cat > "$CONFIG_DIR/systemd/user/overviewlistener.service" << 'EOF'
[Unit]
Description=Overview listener
PartOf=graphical-session.target
After=graphical-session.target

[Service]
ExecStart=%h/.local/bin/overviewlistener
Restart=on-failure

[Install]
WantedBy=graphical-session.target
EOF

# Enable user services
systemctl --user enable swww.service
systemctl --user enable overviewlistener.service

echo ""
echo "10. Setting up default shell to Fish..."
if [[ "$SHELL" != *"fish"* ]]; then
    echo "   Changing default shell to fish..."
    chsh -s "$(which fish)"
    echo "   Please log out and back in for shell changes to take effect."
else
    echo "   Fish is already your default shell"
fi

echo ""
echo "Dotfiles migration setup complete!"
echo ""
echo "Next steps:"
echo "1. Customize your configurations in $CONFIG_DIR"
echo "2. Add your dotfiles to the repository: dots add ."
echo "3. Commit your changes: dots commit -m 'Initial dotfiles setup'"
echo "4. Consider using a remote repository for backup: dots remote add origin <your-repo-url>"
echo ""
echo "Your original configurations have been backed up to: $BACKUP_DIR"
echo ""
echo "To restore from backup, you can copy files from the backup directory:"
echo "  cp -r $BACKUP_DIR/<config> $CONFIG_DIR/"
