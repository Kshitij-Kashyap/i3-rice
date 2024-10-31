#!/bin/bash

# Check if wired connection is active
if nmcli -t -f TYPE,STATE device | grep -q "^ethernet:connected"; then
    # Get the IP address of the wired connection
    ip=$(ip -4 addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
    echo "🌐 $ip"
    exit 0
fi

# Check if wireless connection is active
if nmcli -t -f TYPE,STATE device | grep -q "^wifi:connected"; then
    # Get the SSID of the connected WiFi
    ssid=$(nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d':' -f2)
    echo "📶 $ssid"
    exit 0
fi

# If no connection is active
echo "🔌 No Connection"

