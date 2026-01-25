#!/bin/bash
set -e

# zerobrew installer
# Usage: curl -sSL https://raw.githubusercontent.com/YOUR_USER/zerobrew/main/install.sh | bash

ZEROBREW_REPO="https://github.com/YOUR_USER/zerobrew.git"
ZEROBREW_DIR="$HOME/.zerobrew"
ZEROBREW_BIN="$HOME/.local/bin"

echo "Installing zerobrew..."

# Check for Rust/Cargo
if ! command -v cargo &> /dev/null; then
    echo "Rust not found. Installing via rustup..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
fi

# Ensure cargo is available
if ! command -v cargo &> /dev/null; then
    echo "Error: Cargo still not found after installing Rust"
    exit 1
fi

echo "Rust version: $(rustc --version)"

# Clone or update repo
if [[ -d "$ZEROBREW_DIR" ]]; then
    echo "Updating zerobrew..."
    cd "$ZEROBREW_DIR"
    git pull
else
    echo "Cloning zerobrew..."
    git clone "$ZEROBREW_REPO" "$ZEROBREW_DIR"
    cd "$ZEROBREW_DIR"
fi

# Build
echo "Building zerobrew..."
cargo build --release

# Create bin directory and install binary
mkdir -p "$ZEROBREW_BIN"
cp target/release/zb "$ZEROBREW_BIN/zb"
chmod +x "$ZEROBREW_BIN/zb"
echo "Installed zb to $ZEROBREW_BIN/zb"

# Add zb binary to PATH if not already there
add_to_path() {
    local path_entry="$1"
    local config_file="$2"

    if ! grep -q "$path_entry" "$config_file" 2>/dev/null; then
        echo "" >> "$config_file"
        echo "# zerobrew" >> "$config_file"
        echo "export PATH=\"$path_entry:\$PATH\"" >> "$config_file"
        echo "Added $path_entry to PATH in $config_file"
    fi
}

# Detect shell config file
case "$SHELL" in
    */zsh)
        SHELL_CONFIG="$HOME/.zshrc"
        ;;
    */bash)
        if [[ -f "$HOME/.bash_profile" ]]; then
            SHELL_CONFIG="$HOME/.bash_profile"
        else
            SHELL_CONFIG="$HOME/.bashrc"
        fi
        ;;
    *)
        SHELL_CONFIG="$HOME/.profile"
        ;;
esac

add_to_path "$ZEROBREW_BIN" "$SHELL_CONFIG"

# Export for current session so zb init works
export PATH="$ZEROBREW_BIN:$PATH"

# Run zb init to set up directories and add prefix to PATH
echo ""
echo "Running zb init..."
"$ZEROBREW_BIN/zb" init

echo ""
echo "Installation complete!"
echo ""
echo "To start using zerobrew, either:"
echo "  1. Restart your terminal, or"
echo "  2. Run: source $SHELL_CONFIG"
echo ""
echo "Then try:"
echo "  zb install jq"
echo ""
