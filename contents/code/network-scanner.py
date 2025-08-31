#!/usr/bin/env python3

# Should be in: contents/code/network-scanner.py
# X-Seti Jan 2019, 2025 - network-scanner.py
# SmartLife Controller Widget - Network Scanner Script

import sys
import subprocess
import socket
import json
import time
import argparse
from concurrent.futures import ThreadPoolExecutor

def scan_network(subnet="192.168.1", esp_only=False):
    """Scan the network for devices, optionally filtering for ESP devices"""
    devices = []
    
    def check_host(ip):
        # Try to ping the host
        try:
            result = subprocess.run(
                ["ping", "-c", "1", "-W", "1", ip],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL
            )
            if result.returncode == 0:
                # Try to get hostname
                try:
                    hostname = socket.gethostbyaddr(ip)[0]
                    # If ESP-only filter is on, check if hostname starts with ESP
                    if esp_only and not (hostname.startswith("ESP") or "ESP" in hostname.upper()):
                        return None
                    return {"name": hostname, "ipAddress": ip}
                except socket.herror:
                    # No hostname found, try to check if it's an ESP device by other means
                    if esp_only:
                        # Try connecting to common ESP ports
                        for port in [80, 8080, 8266]:
                            s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                            s.settimeout(0.5)
                            try:
                                s.connect((ip, port))
                                s.close()
                                return {"name": f"Unknown-{ip.split('.')[-1]}", "ipAddress": ip}
                            except:
                                pass
                        return None
                    return {"name": f"Unknown-{ip.split('.')[-1]}", "ipAddress": ip}
        except:
            pass
        return None
    
    # Scan the network using ThreadPoolExecutor for faster scanning
    with ThreadPoolExecutor(max_workers=50) as executor:
        ip_list = [f"{subnet}.{i}" for i in range(1, 255)]
        results = executor.map(check_host, ip_list)
        
        for result in results:
            if result:
                devices.append(result)
    
    return devices

def toggle_device(ip_address, port=80):
    """Toggle a device's state by sending a request to its IP address"""
    try:
        # This is a simplified example. In a real implementation,
        # you would need to use the appropriate protocol for the device.
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.settimeout(2)
        s.connect((ip_address, port))
        s.send(b'TOGGLE\r\n')
        response = s.recv(1024)
        s.close()
        return response.decode('utf-8').strip()
    except Exception as e:
        return f"Error: {str(e)}"

def control_device(ip_address, command, value, port=80):
    """Send a control command to a device"""
    try:
        # This is a simplified example. In a real implementation,
        # you would need to use the appropriate protocol for the device.
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.settimeout(2)
        s.connect((ip_address, port))
        s.send(f"{command}:{value}\r\n".encode('utf-8'))
        response = s.recv(1024)
        s.close()
        return response.decode('utf-8').strip()
    except Exception as e:
        return f"Error: {str(e)}"

def main():
    parser = argparse.ArgumentParser(description='Network scanner for SmartLife devices')
    parser.add_argument('action', choices=['scan', 'scan-esp', 'toggle', 'control'])
    parser.add_argument('--ip', help='IP address for toggle/control actions')
    parser.add_argument('--subnet', default='192.168.1', help='Subnet to scan (default: 192.168.1)')
    parser.add_argument('--command', help='Command for control action')
    parser.add_argument('--value', help='Value for control action')
    args = parser.parse_args()
    
    if args.action == 'scan':
        devices = scan_network(args.subnet, esp_only=False)
        print(json.dumps(devices))
    
    elif args.action == 'scan-esp':
        devices = scan_network(args.subnet, esp_only=True)
        print(json.dumps(devices))
    
    elif args.action == 'toggle':
        if not args.ip:
            print("Error: IP address required for toggle action")
            sys.exit(1)
        response = toggle_device(args.ip)
        print(response)
    
    elif args.action == 'control':
        if not args.ip or not args.command or args.value is None:
            print("Error: IP, command and value required for control action")
            sys.exit(1)
        response = control_device(args.ip, args.command, args.value)
        print(response)

if __name__ == "__main__":
    main()