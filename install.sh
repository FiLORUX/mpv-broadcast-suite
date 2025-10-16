#!/usr/bin/env bash

# mpv Broadcast Suite Installer
# Installs configuration files and scripts to appropriate mpv directories
# Supports Linux and macOS

set -e  # Exit on error

# Colours for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Colour

# Determine mpv config directory
if [[ "$OSTYPE" == "darwin"* ]]; then
    MPV_CONFIG="$HOME/.config/mpv"
    PLATFORM="macOS"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    MPV_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/mpv"
    PLATFORM="Linux"
else
    echo -e "${RED}Error: Unsupported operating system${NC}"
    exit 1
fi

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║       mpv Broadcast Suite Installer (${PLATFORM})           ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if mpv is installed
if ! command -v mpv &> /dev/null; then
    echo -e "${YELLOW}Warning: mpv not found in PATH${NC}"
    echo "Please install mpv before proceeding:"
    echo "  macOS: brew install mpv"
    echo "  Linux: sudo apt install mpv  (or equivalent)"
    echo ""
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check mpv version
if command -v mpv &> /dev/null; then
    MPV_VERSION=$(mpv --version | head -n1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n1)
    echo -e "Detected mpv version: ${GREEN}${MPV_VERSION}${NC}"
    echo ""
fi

# Create directories
echo -e "${BLUE}[1/4]${NC} Creating directories..."
mkdir -p "$MPV_CONFIG/scripts"
mkdir -p "$HOME/mpv_screenshots"
echo -e "${GREEN}✓${NC} Directories created"
echo ""

# Backup existing configuration
echo -e "${BLUE}[2/4]${NC} Checking for existing configuration..."
BACKUP_DIR="$MPV_CONFIG/backup_$(date +%Y%m%d_%H%M%S)"
BACKUP_NEEDED=false

for file in mpv.conf input.conf scripts/timecode.lua scripts/audiomap.lua; do
    if [ -f "$MPV_CONFIG/$file" ]; then
        if [ "$BACKUP_NEEDED" = false ]; then
            mkdir -p "$BACKUP_DIR/scripts"
            BACKUP_NEEDED=true
        fi
        cp "$MPV_CONFIG/$file" "$BACKUP_DIR/$file"
        echo -e "${YELLOW}!${NC} Backed up existing: $file"
    fi
done

if [ "$BACKUP_NEEDED" = true ]; then
    echo -e "${GREEN}✓${NC} Backup created at: $BACKUP_DIR"
else
    echo -e "${GREEN}✓${NC} No existing configuration found"
fi
echo ""

# Install files
echo -e "${BLUE}[3/4]${NC} Installing configuration files..."

# Check if we're in the correct directory
if [ ! -f "mpv.conf" ] || [ ! -f "input.conf" ]; then
    echo -e "${RED}Error: Configuration files not found${NC}"
    echo "Please run this script from the mpv-broadcast-suite directory"
    exit 1
fi

cp mpv.conf "$MPV_CONFIG/"
echo -e "${GREEN}✓${NC} Installed mpv.conf"

cp input.conf "$MPV_CONFIG/"
echo -e "${GREEN}✓${NC} Installed input.conf"

cp scripts/timecode.lua "$MPV_CONFIG/scripts/"
echo -e "${GREEN}✓${NC} Installed timecode.lua"

cp scripts/audiomap.lua "$MPV_CONFIG/scripts/"
echo -e "${GREEN}✓${NC} Installed audiomap.lua"
echo ""

# Verify installation
echo -e "${BLUE}[4/4]${NC} Verifying installation..."
ALL_GOOD=true

for file in mpv.conf input.conf scripts/timecode.lua scripts/audiomap.lua; do
    if [ ! -f "$MPV_CONFIG/$file" ]; then
        echo -e "${RED}✗${NC} Missing: $file"
        ALL_GOOD=false
    fi
done

if [ "$ALL_GOOD" = true ]; then
    echo -e "${GREEN}✓${NC} All files installed successfully"
else
    echo -e "${RED}✗${NC} Some files failed to install"
    exit 1
fi
echo ""

# Installation complete
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║           Installation Complete!                           ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "Configuration installed to: ${BLUE}$MPV_CONFIG${NC}"
echo -e "Screenshots will be saved to: ${BLUE}$HOME/mpv_screenshots${NC}"
echo ""
echo "Quick Start:"
echo "  1. Launch mpv with any video file: mpv your_video.mp4"
echo "  2. Press 't' to toggle timecode display"
echo "  3. Press 'F1' for keyboard shortcuts"
echo "  4. Press 'Ctrl+i' for audio information"
echo ""
echo "Documentation: https://github.com/yourusername/mpv-broadcast-suite"
echo ""
