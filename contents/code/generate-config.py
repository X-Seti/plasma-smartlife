#!/usr/bin/env python3

"""
 X-Seti Jan 2019, 2025 - Device Configuration Generator for SmartLife Controller Widget
This script scans the local network for ESP devices and generates a device configuration file.
"""

import json
import os
import socket
import subprocess
import sys
import time
import re
from concurrent.futures import ThreadPoolExecutor

def get_subnet():
    """Determine the local subnet"""
    try:
        # Get the primary IP address
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        local_ip = s.getsockname()[0]
        s.close()

        # Extract subnet (first three octets)
        subnet = '.'.join(local_ip.split('.')[:3])
        return subnet
    except Exception as e:
        print(f"Could not determine subnet: {e}")
        return "192.168.1"  # Default fallback

def scan_network(subnet, scan_mode):
    """Scan the network for devices"""
    print(f"Scanning subnet {subnet}.* for devices...")
    devices = []

    def check_host(ip):
        try:
            # Try to ping the host
            result = subprocess.run(
                ["ping", "-c", "1", "-W", "1", ip],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL
            )
            if result.returncode == 0:
                # Try to get hostname
                try:
                    hostname = socket.gethostbyaddr(ip)[0]

                    # Check based on scan mode
                    if scan_mode == "esp" and "ESP" in hostname.upper():
                        print(f"✓ Found ESP device: {hostname} ({ip})")
                        return {"name": hostname, "ipAddress": ip, "type": "light"}
                    elif scan_mode == "tuya" and ("TUYA" in hostname.upper() or "SMARTLIFE" in hostname.upper()):
                        print(f"✓ Found Tuya/SmartLife device: {hostname} ({ip})")
                        return {"name": hostname, "ipAddress": ip, "type": "light"}
                    elif scan_mode == "all":
                        # Check if it's a smart device by looking at common patterns in hostname
                        if (any(pattern in hostname.upper() for pattern in ["ESP", "TUYA", "SMART", "IOT", "PLUG", "LIGHT", "BULB", "SWITCH"])):
                            print(f"✓ Found potential smart device: {hostname} ({ip})")
                            return {"name": hostname, "ipAddress": ip, "type": determine_device_type(hostname)}
                        # Check ports even if hostname doesn't match patterns
                        device_type = check_smart_device_ports(ip)
                        if device_type:
                            print(f"✓ Found potential smart device at IP: {ip}")
                            return {"name": hostname, "ipAddress": ip, "type": device_type}
                except socket.herror:
                    # No hostname resolution, check ports based on scan mode
                    if scan_mode == "esp" and check_esp_ports(ip):
                        print(f"✓ Found potential ESP device at IP: {ip}")
                        return {"name": f"ESP-{ip.split('.')[-1]}", "ipAddress": ip, "type": "light"}
                    elif scan_mode == "tuya" and check_tuya_ports(ip):
                        print(f"✓ Found potential Tuya device at IP: {ip}")
                        return {"name": f"Tuya-{ip.split('.')[-1]}", "ipAddress": ip, "type": "light"}
                    elif scan_mode == "all":
                        device_type = check_smart_device_ports(ip)
                        if device_type:
                            print(f"✓ Found potential smart device at IP: {ip}")
                            return {"name": f"SmartDevice-{ip.split('.')[-1]}", "ipAddress": ip, "type": device_type}
            return None
        except:
            return None

    # Scan the network using ThreadPoolExecutor for faster scanning
    with ThreadPoolExecutor(max_workers=50) as executor:
        ip_list = [f"{subnet}.{i}" for i in range(1, 255)]
        results = executor.map(check_host, ip_list)

        for result in results:
            if result:
                devices.append(result)

    return devices

def determine_device_type(hostname):
    """Determine device type based on hostname"""
    hostname = hostname.upper()

    if any(pattern in hostname for pattern in ["LIGHT", "BULB", "LED"]):
        return "light"
    elif any(pattern in hostname for pattern in ["PLUG", "SOCKET", "OUTLET"]):
        return "outlet"
    elif any(pattern in hostname for pattern in ["SWITCH"]):
        return "switch"
    elif any(pattern in hostname for pattern in ["THERMO", "TEMP"]):
        return "thermostat"
    else:
        return "light"  # Default to light

def check_esp_ports(ip):
    """Check if the device has common ESP ports open"""
    esp_ports = [80, 81, 8080, 8081, 8266]

    for port in esp_ports:
        try:
            s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            s.settimeout(0.3)
            result = s.connect_ex((ip, port))
            s.close()
            if result == 0:
                print(f"   └─ Device at {ip} has port {port} open")
                return True
        except:
            pass

    return False

def check_tuya_ports(ip):
    """Check if the device has common Tuya ports open"""
    tuya_ports = [6668, 6669, 6670]

    for port in tuya_ports:
        try:
            s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            s.settimeout(0.3)
            result = s.connect_ex((ip, port))
            s.close()
            if result == 0:
                print(f"   └─ Device at {ip} has port {port} open (Tuya)")
                return True
        except:
            pass

    return False

def check_smart_device_ports(ip):
    """Check if the device has any common smart device ports open and determine type"""
    # Check common smart device ports and infer device type
    port_checks = [
        (80, "generic web interface"),
        (81, "generic web interface"),
        (8080, "generic web interface"),
        (8081, "generic web interface"),
        (6668, "Tuya specific"),
        (6669, "Tuya specific"),
        (6670, "Tuya specific"),
        (8266, "ESP specific"),
        (1883, "MQTT"),
        (8883, "MQTT over TLS")
    ]

    for port, desc in port_checks:
        try:
            s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            s.settimeout(0.3)
            result = s.connect_ex((ip, port))
            s.close()
            if result == 0:
                print(f"   └─ Device at {ip} has port {port} open ({desc})")

                # Try to determine device type based on open ports
                if port in [6668, 6669, 6670]:
                    return "light"  # Most Tuya devices are lights
                elif port == 8266:
                    return "light"  # Most ESP devices are lights
                elif port in [1883, 8883]:
                    return "outlet"  # MQTT often used with smart plugs
                else:
                    return "light"  # Default to light
        except:
            pass

    return None

def generate_device_config(devices):
    """Generate a device configuration file"""
    # Format devices for the QML file
    device_list = []

    for i, device in enumerate(devices):
        device_entry = {
            "id": i + 1,
            "name": device["name"],
            "ipAddress": device["ipAddress"],
            "type": device.get("type", "light"),
            "state": False,
            "brightness": 100,
            "color": "#FFFFFF",
            "timerOn": None,
            "timerOff": None
        }
        device_list.append(device_entry)

    # Add a few sample devices if no devices found
    if not device_list:
        device_list = [
            {
                "id": 1,
                "name": "Sample Light",
                "ipAddress": f"{get_subnet()}.100",
                "type": "light",
                "state": False,
                "brightness": 80,
                "color": "#FFFFFF",
                "timerOn": None,
                "timerOff": None
            },
            {
                "id": 2,
                "name": "Sample Outlet",
                "ipAddress": f"{get_subnet()}.101",
                "type": "outlet",
                "state": False,
                "timerOn": None,
                "timerOff": None
            }
        ]

    return device_list

def save_device_config(device_list, output_path):
    """Save the device configuration to a file"""
    # Create the directory if it doesn't exist
    os.makedirs(os.path.dirname(output_path), exist_ok=True)

    # Convert to JSON format
    device_config = json.dumps(device_list, indent=4)

    # Save to the file
    with open(output_path, 'w') as f:
        f.write(device_config)

    # Also try to directly save to the KDE configuration
    try:
        # Determine the KDE config file path
        home_dir = os.path.expanduser("~")
        kde_config_dir = os.path.join(home_dir, ".config")
        plasma_config_file = None

        # Look for the Plasma configuration file
        for filename in os.listdir(kde_config_dir):
            if filename.startswith("plasma-org.kde.plasma.desktop-") and filename.endswith("rc"):
                plasma_config_file = os.path.join(kde_config_dir, filename)
                break

        if plasma_config_file:
            print(f"Found Plasma configuration file: {plasma_config_file}")
            print("Attempting to update widget configuration directly...")

            # We'll create a file that the widget can read to know it should reload
            reload_flag_file = os.path.join(os.path.dirname(output_path), "reload_config")
            with open(reload_flag_file, 'w') as f:
                f.write("1")
            print(f"Created reload flag file: {reload_flag_file}")
    except Exception as e:
        print(f"Note: Could not directly update KDE configuration: {e}")
        print("The widget will need to be restarted to pick up the new configuration.")

    print(f"\n{'-' * 50}")
    print(f"Device configuration saved to {output_path}")
    print(f"Found {len(device_list)} device(s):")

    # Print detailed device information
    for i, device in enumerate(device_list):
        print(f"\n{i+1}. {device['name']} ({device['ipAddress']})")
        print(f"   Type: {device['type']}")
        if device['type'] == 'light':
            print(f"   Brightness: {device['brightness']}%")
            print(f"   Color: {device['color']}")
        print(f"   Initial state: {'ON' if device['state'] else 'OFF'}")

    print(f"\n{'-' * 50}")
    print("\n*** IMPORTANT ***")
    print("To make the widget use this configuration immediately:")
    print("1. Open the widget settings (right-click the widget → Configure...)")
    print("2. In the 'Device List' section, click 'Reset Device List'")
    print("3. Copy and paste the following JSON into the text field:")
    print("-" * 30)
    print(device_config)
    print("-" * 30)
    print("4. Click 'OK' to save the configuration")

    return device_config

def main():
    print("\n" + "=" * 60)
    print("  SmartLife Controller Widget - Device Configuration Generator")
    print("=" * 60 + "\n")

    # Determine target directory
    home_dir = os.path.expanduser("~")
    target_dir = os.path.join(home_dir, ".local", "share", "plasma", "plasmoids", "org.kde.plasma.smartlifecontroller")
    config_path = os.path.join(target_dir, "contents", "code", "device-config.json")

    print("This script will scan your network for smart devices and generate a configuration file.")
    print(f"Configuration will be saved to: {config_path}")

    # Ask for confirmation
    response = input("\nDo you want to proceed with network scanning? (y/n): ")
    if response.lower() != 'y':
        print("Operation cancelled.")
        return

    # Get subnet
    subnet = get_subnet()
    print(f"\nDetected local subnet: {subnet}.*")

    # Option to change subnet
    response = input("Is this correct? (y/n, if n you can specify a different subnet): ")
    if response.lower() != 'y':
        subnet = input("Enter subnet (e.g., 192.168.0): ")

    # Ask for scan mode
    print("\nSelect scan mode:")
    print("1. ESP devices only (look for ESP in hostname)")
    print("2. Tuya/SmartLife devices only (look for Tuya/SmartLife in hostname)")
    print("3. All potential smart devices (comprehensive scan)")

    scan_choice = input("\nEnter your choice (1/2/3): ")

    if scan_choice == "1":
        scan_mode = "esp"
        print("\nScanning for ESP devices only...")
    elif scan_choice == "2":
        scan_mode = "tuya"
        print("\nScanning for Tuya/SmartLife devices only...")
    else:
        scan_mode = "all"
        print("\nScanning for all potential smart devices...")

    print("-" * 50)

    # Scan network
    devices = scan_network(subnet, scan_mode)

    if not devices:
        print("\n⚠️  No devices found on the network.")
        print("Possible reasons:")
        print("  - Smart devices might be powered off")
        print("  - Devices might be on a different subnet")
        print("  - Devices might not have recognizable hostnames")
        print("  - Firewall might be blocking the scan")

        # Ask if user wants to manually add a device
        response = input("\nWould you like to manually add a device? (y/n): ")
        if response.lower() == 'y':
            device_ip = input("Enter device IP address: ")
            device_name = input("Enter device name: ")
            device_type = input("Enter device type (light/outlet/switch/thermostat): ")

            if not device_type or device_type not in ["light", "outlet", "switch", "thermostat"]:
                device_type = "light"  # Default to light

            devices = [{
                "id": 1,
                "name": device_name or f"Manual-{device_ip.split('.')[-1]}",
                "ipAddress": device_ip,
                "type": device_type,
                "state": False,
                "brightness": 80,
                "color": "#FFFFFF",
                "timerOn": None,
                "timerOff": None
            }]
            print(f"✓ Added device: {device_name} at {device_ip}")

    # Generate device configuration
    device_list = generate_device_config(devices)

    # Save device configuration
    save_device_config(device_list, config_path)

    print("\nDone! The widget will use this configuration when you restart Plasma.")
    print("If you want to update the configuration later, just run this script again.")
    print("\nReminder: You can add and edit devices directly from the widget interface too!")


if __name__ == "__main__":
    main()
