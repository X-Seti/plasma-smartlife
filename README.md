X-Seti Jan 2019, 2025 SmartLife Controller Widget for KDE Plasma 6

# SmartLife Controller Widget for KDE Plasma 6

A KDE Plasma 6 widget for controlling SmartLife/Tuya ESP-based smart home devices directly from your desktop.

## Features

- **Device Discovery**: Automatically scan your network for ESP-based SmartLife devices
- **Device Control**: Toggle devices on/off, adjust brightness, change colors
- **Timer Support**: Set timers to automatically turn devices on/off at specified times
- **ARGB Color Control**: Full RGB color control with visual color picker
- **Light/Dark Settings**: Adjust brightness from full light to complete darkness
- **Device Management**: Add, edit, and remove devices with ease

## Device Discovery

The widget includes a powerful device discovery tool that can:

1. **Scan for Multiple Device Types**:
   - ESP devices (devices with "ESP" in their hostname)
   - Tuya/SmartLife devices (with "TUYA" or "SMARTLIFE" in hostname)
   - Any potential smart device (comprehensive scan)

2. **Port-Based Detection**:
   - Identifies devices based on open ports commonly used by IoT devices
   - Detects devices even without recognizable hostnames
   - Automatically determines device type based on port patterns

3. **Manual Configuration**:
   - Add devices manually if automatic detection fails
   - Specify IP address, name, and type for any device
   - Edit existing devices through the widget interface

## Requirements

- KDE Plasma 6
- Python 3.6+
- Python `requests` package

## Installation

### Using the Installation Script

1. Download and extract the package
2. Open a terminal in the extracted directory
3. Run the installation script:
   ```bash
   chmod +x install.sh
   ./install.sh
   ```
4. Follow the on-screen instructions

### Manual Installation

If you prefer to install manually:

1. Create the required directories:
   ```bash
   mkdir -p ~/.local/share/plasma/plasmoids/org.kde.plasma.smartlifecontroller/contents/ui
   mkdir -p ~/.local/share/plasma/plasmoids/org.kde.plasma.smartlifecontroller/contents/code
   mkdir -p ~/.local/share/plasma/plasmoids/org.kde.plasma.smartlifecontroller/contents/config
   ```

2. Copy the files to their respective locations:
   ```bash
   cp metadata.json ~/.local/share/plasma/plasmoids/org.kde.plasma.smartlifecontroller/
   cp contents/ui/* ~/.local/share/plasma/plasmoids/org.kde.plasma.smartlifecontroller/contents/ui/
   cp contents/code/* ~/.local/share/plasma/plasmoids/org.kde.plasma.smartlifecontroller/contents/code/
   cp contents/config/* ~/.local/share/plasma/plasmoids/org.kde.plasma.smartlifecontroller/contents/config/
   ```

3. Make the Python scripts executable:
   ```bash
   chmod +x ~/.local/share/plasma/plasmoids/org.kde.plasma.smartlifecontroller/contents/code/network-scanner.py
   chmod +x ~/.local/share/plasma/plasmoids/org.kde.plasma.smartlifecontroller/contents/code/generate-config.py
   ```

4. Install the required Python package:
   ```bash
   pip3 install requests
   ```

5. Restart Plasma:
   ```bash
   kquitapp5 plasmashell && kstart5 plasmashell
   ```

## Adding the Widget to Your Desktop

1. Right-click on your desktop or panel
2. Select "Add Widgets"
3. Search for "SmartLife"
4. Drag the SmartLife Controller widget to your desktop or panel

## Usage

### Scanning for Devices

1. Click the "Scan Network" button to find all compatible devices on your network
2. ESP devices will be automatically detected and added to your device list

### Controlling Devices

1. Click on a device to open the detailed control panel
2. Use the tabs to access different control options:
   - **Basic**: Power toggle, brightness slider, light temperature
   - **Colors**: RGB color picker and preset colors
   - **Timer**: Set automatic on/off timers

### Device Management

1. Click the "Add Device" button to manually add a device
2. Use the "Scan for ESP Devices" button to automatically find ESP devices
3. Toggle the "Show Offline" option to display devices that are currently offline
4. Use the filter box to quickly find specific devices

## Uninstallation

### Using the Uninstallation Script

1. Open a terminal in the package directory
2. Run the uninstallation script:
   ```bash
   chmod +x uninstall.sh
   ./uninstall.sh
   ```
3. Follow the on-screen instructions

### Manual Uninstallation

1. Remove the widget directory:
   ```bash
   rm -rf ~/.local/share/plasma/plasmoids/org.kde.plasma.smartlifecontroller
   ```

2. Restart Plasma:
   ```bash
   kquitapp5 plasmashell && kstart5 plasmashell
   ```

## Troubleshooting

If you encounter any issues:

- **Widget doesn't appear in the widget list**: Try restarting your computer or running `kbuildsycoca5` in a terminal
- **Network scanning doesn't work**: Make sure Python and the requests package are installed
- **Device control doesn't work**: Check that your devices are on the same network as your computer
- **Errors in the widget**: Check the Plasma logs using `journalctl -f -u plasma*`

## File Structure

All files have standardized headers indicating their location and purpose:

```
// Should be in: contents/ui/main.qml
// X-Seti Jan 2019, 2025 - main.qml
// SmartLife Controller Widget - Main UI
```

This makes it easy to identify where each file belongs in the project structure.

## License

This widget is released under the GPL v3 License.

## Attribution

Created by X-Seti, Jan 2019-2025.
