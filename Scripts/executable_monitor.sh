#!/bin/bash

# Enable debug mode
set -x

# Configurable variables
EXTERNAL_NAME="DP-1"  # Set your external monitor name here (check with swaymsg -t get_outputs)
EXTERNAL_HZ=165       # Set your desired refresh rate here
EXTERNAL_RES="1920x1080"  # Set your external monitor's resolution here

# Function to get display names using jq
get_displays() {
    LAPTOP=$(swaymsg -t get_outputs | jq -r '.[] | select(.name | startswith("eDP")) | .name')
    EXTERNAL=$(swaymsg -t get_outputs | jq -r --arg EXTERNAL_NAME "$EXTERNAL_NAME" '.[] | select(.name == $EXTERNAL_NAME) | .name')

    echo "Detected laptop display: $LAPTOP"
    echo "Detected external display: $EXTERNAL"

    if [ -z "$LAPTOP" ]; then
        echo "Error: Couldn't detect laptop display."
        exit 1
    fi

    if [ -z "$EXTERNAL" ]; then
        echo "Warning: Couldn't detect external display. Check your external monitor name."
        # Optional: Exit or fallback to single monitor mode if external not found
    fi
}

# Function to check if a display is active
is_active() {
    swaymsg -t get_outputs | jq -r --arg display "$1" '.[] | select(.name == $display) | .active' | grep true > /dev/null
}

# Function to switch to single monitor (laptop screen only)
switch_to_single() {
    echo "Switching to single monitor mode"
    if [ -n "$EXTERNAL" ]; then
        swaymsg output "$EXTERNAL" disable
    fi
    swaymsg output "$LAPTOP" enable
    swaymsg output "$LAPTOP" position 0 0
}

# Function to switch to dual monitor setup
switch_to_dual() {
    if [ -n "$EXTERNAL" ]; then
        echo "Switching to dual monitor mode"
        swaymsg output "$LAPTOP" enable
        swaymsg output "$LAPTOP" position 1920 0  # Laptop as primary
        swaymsg output "$EXTERNAL" enable
        swaymsg output "$EXTERNAL" mode "${EXTERNAL_RES}@${EXTERNAL_HZ}Hz"
        swaymsg output "$EXTERNAL" position 0 0  # External to the right
    else
        echo "Error: External monitor not detected. Staying in single monitor mode."
        switch_to_single
    fi
}

# Get display names
get_displays

# Check current setup and switch accordingly
if [ -n "$EXTERNAL" ] && is_active "$EXTERNAL" && ! is_active "$LAPTOP"; then
    echo "Currently in dual monitor mode. Switching to single monitor (laptop only)."
    switch_to_single
else
    echo "Currently in single monitor mode or external monitor is inactive. Switching to dual monitor setup."
    switch_to_dual
fi

# Disable debug mode
set +x

