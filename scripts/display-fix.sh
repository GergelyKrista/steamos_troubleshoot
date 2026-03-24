#!/bin/bash
# Steam Deck External Monitor Fix - Enhanced Version
# Handles both connection and disconnection of external monitors
# Prevents KScreen switching loop

# Log function for debugging
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> /home/deck/.config/display-fix.log
}

log "Display fix script started"

# Kill KScreen to prevent switching loop
pkill -9 kscreen_backend_launcher 2>/dev/null
pkill -9 kscreen 2>/dev/null
log "KScreen processes killed"

# Wait for display detection to stabilize
sleep 2

# Find xrandr binary
# Find xrandr from Steam Runtime (version in path changes with updates)
XRANDR=$(find /home/deck/.local/share/Steam/steamapps/common/SteamLinuxRuntime_soldier -name "xrandr" -type f 2>/dev/null | head -1)

if [ ! -f "$XRANDR" ]; then
    log "ERROR: xrandr binary not found"
    exit 1
fi

# Force GPU to re-probe connectors (needed after Game Mode → Desktop Mode switch)
# xrandr query triggers the kernel DRM subsystem to re-scan all outputs
DISPLAY=:0 "$XRANDR" --query > /dev/null 2>&1
sleep 1

# If still disconnected, try toggling the output to force re-detection
EXTERNAL_STATUS=$(cat /sys/class/drm/card0-DP-1/status 2>/dev/null)
log "External monitor status (first check): $EXTERNAL_STATUS"

if [ "$EXTERNAL_STATUS" != "connected" ]; then
    log "Monitor not detected, forcing re-probe..."
    # Force xrandr to attempt enabling the output - this triggers a deeper HPD re-check
    DISPLAY=:0 "$XRANDR" --output DisplayPort-0 --auto 2>/dev/null
    sleep 2
    # Re-read status after forced probe
    EXTERNAL_STATUS=$(cat /sys/class/drm/card0-DP-1/status 2>/dev/null)
    log "External monitor status (after re-probe): $EXTERNAL_STATUS"
fi

if [ "$EXTERNAL_STATUS" != "connected" ]; then
    # Last resort: cycle the internal display to trigger a full modeset
    log "Still not detected, cycling modeset..."
    DISPLAY=:0 "$XRANDR" --output eDP --off 2>/dev/null
    sleep 1
    DISPLAY=:0 "$XRANDR" --output eDP --auto 2>/dev/null
    sleep 2
    EXTERNAL_STATUS=$(cat /sys/class/drm/card0-DP-1/status 2>/dev/null)
    log "External monitor status (after modeset cycle): $EXTERNAL_STATUS"
fi

if [ "$EXTERNAL_STATUS" = "connected" ]; then
    # External monitor is connected
    log "Configuring for external monitor"

    # GAMING MODE: External monitor only (internal display OFF)
    # This prevents fullscreen games from getting confused about which display to use
    DISPLAY=:0 "$XRANDR" --output DisplayPort-0 --mode 1920x1080 --rate 60 --primary --output eDP --off

    # Option 2: External monitor primary + internal display extended (both active)
    # Uncomment below and comment above if you want both displays active
    # DISPLAY=:0 "$XRANDR" --output DisplayPort-0 --mode 1920x1080 --rate 60 --primary \
    #                      --output eDP --mode 800x1280 --rate 90 --rotate right --left-of DisplayPort-0

    log "External monitor configured (internal display OFF for gaming)"
else
    # External monitor is NOT connected - use internal display only
    log "No external monitor detected, configuring internal display"

    # Turn off external display and enable internal display as primary
    DISPLAY=:0 "$XRANDR" --output eDP --mode 800x1280 --rate 90 --rotate right --primary \
                         --output DisplayPort-0 --off 2>/dev/null

    log "Internal display configured as primary"
fi

log "Display configuration complete"
