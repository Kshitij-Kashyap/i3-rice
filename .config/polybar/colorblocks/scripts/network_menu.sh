#!/bin/bash

# Function to connect to a wired network
connect_wired() {
    nmcli device connect eth0 || notify-send "Failed to connect to wired network"
}

# Function to list and connect to wireless networks
connect_wireless() {
    chosen_network=$(nmcli -t -f ssid dev wifi | rofi -dmenu -p "Select WiFi Network")

    # Exit if no network is chosen
    if [ -z "$chosen_network" ]; then
        exit
    fi

    nmcli device wifi connect "$chosen_network" || notify-send "Failed to connect to $chosen_network"
}

# Check if a wired connection is available
if nmcli -t -f TYPE,STATE device | grep -q "^ethernet:connected"; then
    connect_wired
else
    connect_wireless
fi

