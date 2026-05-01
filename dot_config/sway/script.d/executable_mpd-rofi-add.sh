#!/usr/bin/env bash

# 1. Get current status
STATUS=$(mpc status | head -n 2 | tail -n 1 | awk '{print $1}' | tr -d '[]')
[ -z "$STATUS" ] && STATUS="Stopped"

# 2. Main Menu
options="Search & Play\nPlay/Pause\nStop\nNext\nPrevious"
chosen=$(echo -e "$options" | rofi -dmenu -i -p "MPD [$STATUS]")

case "$chosen" in
    "Search & Play")
        # 1. We get the raw paths for MPD to use later
        RAW_LIST=$(mpc listall)
        
        # 2. We get a pretty list. 
        # Format: Artist - Title. If tags are missing, it shows the path.
        # 'sed' cleans up the " - " if both tags are missing.
        DISPLAY_LIST=$(mpc listall -f "[[%artist% - ]%title%]|[%file%]" | sed 's|^ - ||')
        
        # 3. Show Rofi and get the line number (index)
        line_num=$(echo "$DISPLAY_LIST" | rofi -dmenu -i -p "Select Music" -format 'i')

        if [ -n "$line_num" ]; then
            # 4. Use the index to get the exact file path from RAW_LIST
            # Adding 1 because line_num is 0-indexed and sed is 1-indexed
            target_file=$(echo "$RAW_LIST" | sed -n "$((line_num + 1))p")
            
            mpc clear
            mpc add "$target_file"
            mpc play
            
            # Get the pretty name for the notification
            song_info=$(echo "$DISPLAY_LIST" | sed -n "$((line_num + 1))p")
            notify-send "MPD" "Playing: $song_info"
        fi
        ;;
        
    "Play/Pause") mpc toggle ;;
    "Stop") mpc stop ;;
    "Next") mpc next ;;
    "Previous") mpc prev ;;
    *) exit 1 ;;
esac
