#!/bin/bash

# Should be in: uninstall.sh (root directory)
# X-Seti Jan 2019, 2025 - uninstall.sh
# SmartLife Controller Widget - Uninstallation Script

# ANSI color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print banner
echo -e "${BLUE}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║                                                            ║"
echo "║               SmartLife Controller Widget                  ║"
echo "║                   Uninstallation Script                    ║"
echo "║                                                            ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Set target directory
TARGET_DIR="$HOME/.local/share/plasma/plasmoids/org.kde.plasma.smartlifecontroller"

# Check if widget is installed
if [ ! -d "$TARGET_DIR" ]; then
    echo -e "${YELLOW}The widget is not installed at:${NC} $TARGET_DIR"
    exit 0
fi

# Confirm uninstallation
echo -e "${YELLOW}Are you sure you want to uninstall the SmartLife Controller Widget? (y/n)${NC}"
read -r answer
if [[ "$answer" != "y" && "$answer" != "Y" ]]; then
    echo -e "${BLUE}Uninstallation cancelled.${NC}"
    exit 0
fi

# Backup configuration
CONFIG_FILE="$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc"
if [ -f "$CONFIG_FILE" ]; then
    echo -e "${BLUE}Backing up Plasma configuration...${NC}"
    cp "$CONFIG_FILE" "$CONFIG_FILE.backup"
    echo -e "${GREEN}Backup created:${NC} $CONFIG_FILE.backup"
fi

# Remove widget directory
echo -e "${BLUE}Removing widget files...${NC}"
rm -rf "$TARGET_DIR"

# Check if removal was successful
if [ ! -d "$TARGET_DIR" ]; then
    echo -e "${GREEN}Widget files have been removed successfully.${NC}"
else
    echo -e "${RED}Failed to remove widget files. Please remove them manually:${NC} $TARGET_DIR"
fi

# Ask to reload Plasma
echo -e "${YELLOW}Do you want to reload Plasma to apply changes? (y/n)${NC}"
read -r answer
if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
    echo -e "${BLUE}Reloading Plasma...${NC}"
    if command -v kquitapp5 >/dev/null 2>&1; then
        kquitapp5 plasmashell && kstart5 plasmashell
    else
        killall plasmashell && kstart5 plasmashell
    fi
    echo -e "${GREEN}Plasma reloaded.${NC}"
else
    echo -e "${YELLOW}Please log out and log back in or restart Plasma to apply changes.${NC}"
fi

echo -e "${GREEN}✓ SmartLife Controller Widget has been successfully uninstalled!${NC}"
echo -e "${YELLOW}Note: If the widget is still visible on your desktop or panel, you may need to remove it manually.${NC}"
