#!/bin/bash

# Should be in: install.sh (root directory)
# X-Seti Jan 2019, 2025 - install.sh
# SmartLife Controller Widget - Installation Script

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
echo "║                     Installation Script                    ║"
echo "║                                                            ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Get the directory where the script is located
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

# Set target directory
TARGET_DIR="$HOME/.local/share/plasma/plasmoids/org.kde.plasma.smartlifecontroller"

# Check if widget is already installed
if [ -d "$TARGET_DIR" ]; then
    echo -e "${YELLOW}The widget is already installed at:${NC} $TARGET_DIR"
    echo -e "${YELLOW}Do you want to reinstall it? (y/n)${NC}"
    read -r answer
    if [[ "$answer" != "y" && "$answer" != "Y" ]]; then
        echo -e "${BLUE}Installation cancelled.${NC}"
        exit 0
    fi
    echo -e "${YELLOW}Removing old installation...${NC}"
    rm -rf "$TARGET_DIR"
fi

# Create target directory
echo -e "${BLUE}Creating directory structure...${NC}"
mkdir -p "$TARGET_DIR/contents/ui"
mkdir -p "$TARGET_DIR/contents/code"
mkdir -p "$TARGET_DIR/contents/config"

# Copy files
echo -e "${BLUE}Copying files...${NC}"

# Copy metadata.json
if [ -f "$SCRIPT_DIR/metadata.json" ]; then
    cp "$SCRIPT_DIR/metadata.json" "$TARGET_DIR/"
    echo -e "${GREEN}Copied:${NC} metadata.json"
else
    echo -e "${RED}Error:${NC} metadata.json not found!"
    exit 1
fi

# Copy UI files
if [ -f "$SCRIPT_DIR/contents/ui/main.qml" ]; then
    cp "$SCRIPT_DIR/contents/ui/main.qml" "$TARGET_DIR/contents/ui/"
    echo -e "${GREEN}Copied:${NC} main.qml"
else
    echo -e "${RED}Error:${NC} main.qml not found!"
    exit 1
fi

if [ -f "$SCRIPT_DIR/contents/ui/DeviceItem.qml" ]; then
    cp "$SCRIPT_DIR/contents/ui/DeviceItem.qml" "$TARGET_DIR/contents/ui/"
    echo -e "${GREEN}Copied:${NC} DeviceItem.qml"
else
    echo -e "${RED}Error:${NC} DeviceItem.qml not found!"
    exit 1
fi

if [ -f "$SCRIPT_DIR/contents/ui/configGeneral.qml" ]; then
    cp "$SCRIPT_DIR/contents/ui/configGeneral.qml" "$TARGET_DIR/contents/ui/"
    echo -e "${GREEN}Copied:${NC} configGeneral.qml"
else
    echo -e "${RED}Error:${NC} configGeneral.qml not found!"
    exit 1
fi

# Copy config files
if [ -f "$SCRIPT_DIR/contents/config/config.qml" ]; then
    cp "$SCRIPT_DIR/contents/config/config.qml" "$TARGET_DIR/contents/config/"
    echo -e "${GREEN}Copied:${NC} config.qml"
else
    echo -e "${RED}Error:${NC} config.qml not found!"
    exit 1
fi

# Copy and make executable the network scanner script
if [ -f "$SCRIPT_DIR/contents/code/network-scanner.py" ]; then
    cp "$SCRIPT_DIR/contents/code/network-scanner.py" "$TARGET_DIR/contents/code/"
    chmod +x "$TARGET_DIR/contents/code/network-scanner.py"
    echo -e "${GREEN}Copied and made executable:${NC} network-scanner.py"
else
    echo -e "${RED}Error:${NC} network-scanner.py not found!"
    exit 1
fi

# Copy and make executable the device config generator
if [ -f "$SCRIPT_DIR/contents/code/generate-config.py" ]; then
    cp "$SCRIPT_DIR/contents/code/generate-config.py" "$TARGET_DIR/contents/code/"
    chmod +x "$TARGET_DIR/contents/code/generate-config.py"
    echo -e "${GREEN}Copied and made executable:${NC} generate-config.py"
else
    echo -e "${RED}Error:${NC} generate-config.py not found!"
    exit 1
fi

# Copy default.json if it exists
if [ -f "$SCRIPT_DIR/contents/code/default.json" ]; then
    cp "$SCRIPT_DIR/contents/code/default.json" "$TARGET_DIR/contents/code/"
    echo -e "${GREEN}Copied:${NC} default.json"
else
    echo -e "${YELLOW}Warning:${NC} default.json not found, creating a default one"
    cat > "$TARGET_DIR/contents/code/default.json" << 'EOF'
[
  {
    "_comment": "Should be in: contents/code/default.json",
    "_author": "X-Seti Jan 2019, 2025 - default.json",
    "_description": "SmartLife Controller Widget - Default Device Configuration",
    
    "id": 1,
    "name": "Sample Light",
    "ipAddress": "192.168.1.100",
    "type": "light",
    "state": false,
    "brightness": 80,
    "color": "#FFFFFF",
    "timerOn": null,
    "timerOff": null
  }
]
EOF
    echo -e "${GREEN}Created:${NC} default.json"
fi

# Check for Python and required packages
echo -e "${BLUE}Checking dependencies...${NC}"

# Check for Python
if command -v python3 >/dev/null 2>&1; then
    echo -e "${GREEN}Found Python 3${NC}"
else
    echo -e "${RED}Python 3 is not installed. Please install Python 3 to use this widget.${NC}"
    exit 1
fi

# Check for required Python packages
echo -e "${BLUE}Checking for required Python packages...${NC}"

if python3 -c "import requests" 2>/dev/null; then
    echo -e "${GREEN}Found package:${NC} requests"
else
    echo -e "${YELLOW}The requests package is not installed.${NC}"
    echo -e "${YELLOW}Do you want to install it now? (y/n)${NC}"
    read -r answer
    if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
        echo -e "${BLUE}Installing requests package...${NC}"
        pip3 install requests
        if [ $? -ne 0 ]; then
            echo -e "${RED}Failed to install requests package. Please install it manually with 'pip3 install requests'${NC}"
        else
            echo -e "${GREEN}Successfully installed requests package.${NC}"
        fi
    else
        echo -e "${YELLOW}Skipping installation of requests package. Some features may not work correctly.${NC}"
    fi
fi

# Run the device configuration generator
echo -e "${BLUE}Would you like to scan your network for smart devices now? (y/n)${NC}"
read -r answer
if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
    echo -e "${BLUE}Running device configuration generator...${NC}"
    python3 "$TARGET_DIR/contents/code/generate-config.py"
else
    echo -e "${YELLOW}You can run the device configuration generator later by executing:${NC}"
    echo -e "${YELLOW}python3 $TARGET_DIR/contents/code/generate-config.py${NC}"
fi

# Ask to reload Plasma
echo -e "${BLUE}Installation completed!${NC}"
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

echo -e "${GREEN}✓ SmartLife Controller Widget has been successfully installed!${NC}"
echo -e "${BLUE}To add the widget to your desktop or panel:${NC}"
echo "  1. Right-click on your desktop or panel"
echo "  2. Select 'Add Widgets'"
echo "  3. Search for 'SmartLife'"
echo "  4. Drag the SmartLife Controller widget to your desktop or panel"
echo ""
echo -e "${BLUE}Thank you for installing SmartLife Controller Widget!${NC}"
