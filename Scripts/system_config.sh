#!/bin/bash

# Check if user is root, if not exit
if [[ ${EUID} -ne 0 ]]; then
	echo "Please run as root"
	exit
fi

# Sway script
cat <<EOF >/usr/local/bin/sw
#!/usr/bin/env bash
export SDL_VIDEODRIVER=wayland
export QT_QPA_PLATFORM=wayland
export XDG_CURRENT_DESKTOP=sway
export XDG_SESSION_DESKTOP=sway
exec sway --unsupported-gpu "\$@"
exec ags
EOF

# Make it executable
chmod +x /usr/local/bin/sw

# Add wayland session to /usr/share/wayland-sessions/sw.desktop
cat <<EOF >/usr/share/wayland-sessions/sw.desktop
[Desktop Entry]
Name=sw
Comment=Sway with Environment Variables for Wayland
Exec=/usr/local/bin/sw
Type=Application
EOF
