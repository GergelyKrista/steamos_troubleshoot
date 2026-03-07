#!/bin/bash
# Reset external display after Game Mode -> Desktop Mode switch
# This resets the USB hub to force DP Alt Mode re-negotiation

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> /home/deck/.config/display-fix.log
}

log "=== Display reset triggered ==="

EXTERNAL_STATUS=$(cat /sys/class/drm/card0-DP-1/status 2>/dev/null)

if [ "$EXTERNAL_STATUS" = "connected" ]; then
    log "Monitor already connected, no reset needed"
    echo "Monitor is already connected. Running display-fix..."
    /home/deck/.config/display-fix.sh
    exit 0
fi

echo "Monitor not detected. Resetting USB hub to force DP re-negotiation..."
log "Resetting USB hub (GenesysLogic 05e3:0626)"

# Unbind and rebind the USB3 hub to force full re-enumeration
# This makes the dock re-negotiate DisplayPort Alt Mode
USB3_HUB="2-1"
if [ -d "/sys/bus/usb/devices/$USB3_HUB" ]; then
    sudo bash -c "echo 0 > /sys/bus/usb/devices/$USB3_HUB/authorized" 2>/dev/null
    sleep 2
    sudo bash -c "echo 1 > /sys/bus/usb/devices/$USB3_HUB/authorized" 2>/dev/null
    log "USB3 hub reset complete"
else
    log "USB3 hub not found at $USB3_HUB"
fi

# Also reset USB2 side
USB2_HUB="1-1"
if [ -d "/sys/bus/usb/devices/$USB2_HUB" ]; then
    sudo bash -c "echo 0 > /sys/bus/usb/devices/$USB2_HUB/authorized" 2>/dev/null
    sleep 1
    sudo bash -c "echo 1 > /sys/bus/usb/devices/$USB2_HUB/authorized" 2>/dev/null
    log "USB2 hub reset complete"
fi

echo "Waiting for display to re-appear..."
sleep 3

# Check if it came back
EXTERNAL_STATUS=$(cat /sys/class/drm/card0-DP-1/status 2>/dev/null)
log "After USB reset, monitor status: $EXTERNAL_STATUS"

if [ "$EXTERNAL_STATUS" = "connected" ]; then
    echo "Monitor detected! Configuring display..."
    /home/deck/.config/display-fix.sh
else
    echo "Monitor still not detected."
    echo ""
    echo "Try these steps:"
    echo "  1. Unplug and replug the USB-C cable"
    echo "  2. Try a different USB-C port on the dock"
    echo "  3. Check: cat /sys/class/drm/card0-DP-1/status"
    log "USB reset did not recover monitor"
fi
