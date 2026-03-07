# External Display Lost After Switching Game Mode → Desktop Mode

**Date:** 2026-03-07
**Issue:** External monitor works in Game Mode but becomes undetected after switching to Desktop Mode

---

## What Is The Issue?

### Problem
When switching from **Game Mode** to **Desktop Mode**, the external monitor stops being detected. The kernel reports `disconnected` on `card0-DP-1` even though the cable is physically plugged in.

### Root Cause
During the Game Mode → Desktop Mode transition:

1. **Gamescope** (Game Mode compositor) releases the DisplayPort output
2. **KDE/KWin** takes over display management in Desktop Mode
3. The DisplayPort link drops during this handoff and the **DP AUX channel never re-negotiates**
4. The USB-C dock continues working for USB devices (keyboard, mouse, ethernet) but DP Alt Mode is lost
5. `xrandr` and software-level probing **cannot** recover the link — it requires a hardware-level re-negotiation

### How to Confirm This Issue
```bash
# Check if monitor is physically seen by the kernel
cat /sys/class/drm/card0-DP-1/status
# Shows "disconnected" even though cable is plugged in

# USB devices on the dock still work
ls /sys/bus/usb/devices/*/product
# Shows your keyboard, mouse, ethernet adapter, etc.

# EDID is empty (no monitor data received)
cat /sys/class/drm/card0-DP-1/edid | wc -c
# Shows 0
```

---

## Fix Options

### Option 1: Quick Fix — Unplug and Replug Cable
Simply unplug the USB-C cable from the Steam Deck and plug it back in. The `display-fix.sh` script (triggered by udev/autostart) will automatically configure the display.

### Option 2: USB Hub Reset (No Unplug Needed)
Reset the USB hub to force DP Alt Mode re-negotiation. Run this **in Konsole on the host** (not inside a container):

```bash
# Reset the USB3 hub (adjust device path if needed)
sudo bash -c 'echo 0 > /sys/bus/usb/devices/2-1/authorized && sleep 2 && echo 1 > /sys/bus/usb/devices/2-1/authorized'

# Wait for re-detection
sleep 3

# Check if monitor came back
cat /sys/class/drm/card0-DP-1/status

# If connected, run display config
/home/deck/.config/display-fix.sh
```

Or use the provided script:
```bash
/home/deck/.config/reset-display.sh
```

### Option 3: Full xHCI Controller Reset (Nuclear Option)
If the USB hub reset doesn't work, reset the entire USB controller:

```bash
# Find your xHCI controller
XHCI_DEV=$(basename $(readlink /sys/bus/usb/devices/usb2/..))

# Unbind and rebind
sudo bash -c "echo '$XHCI_DEV' > /sys/bus/pci/drivers/xhci_hcd/unbind"
sleep 2
sudo bash -c "echo '$XHCI_DEV' > /sys/bus/pci/drivers/xhci_hcd/bind"
sleep 3

# Check status
cat /sys/class/drm/card0-DP-1/status
```

**Warning:** This will temporarily disconnect ALL USB devices on that controller (keyboard, mouse, etc). They will reconnect automatically after rebind.

---

## Automated Fix: Updated display-fix.sh

The `display-fix.sh` script has been updated with:
1. **Force re-probe** via `xrandr --query` after mode switch
2. **Automatic `--output DisplayPort-0 --auto`** to trigger deeper HPD check
3. **Modeset cycle** as a last resort before falling back to internal-only

See `scripts/display-fix.sh` in this repo for the updated version.

---

## Prevention: Add a Desktop Mode Switch Hook

Create a systemd user service that runs the display reset when Desktop Mode starts:

```bash
mkdir -p ~/.config/systemd/user

cat > ~/.config/systemd/user/display-reset-on-desktop.service << 'EOF'
[Unit]
Description=Reset display after Game Mode switch
After=plasma-kwin_x11.service

[Service]
Type=oneshot
ExecStartPre=/bin/sleep 3
ExecStart=/home/deck/.config/display-fix.sh
RemainAfterExit=yes

[Install]
WantedBy=default.target
EOF

systemctl --user daemon-reload
systemctl --user enable display-reset-on-desktop.service
```

---

## Diagnostic Commands

```bash
# Full display status check
echo "=== DRM Status ===" && \
echo "Internal: $(cat /sys/class/drm/card0-eDP-1/enabled)" && \
echo "External: $(cat /sys/class/drm/card0-DP-1/status)" && \
echo "" && \
echo "=== USB Devices ===" && \
for dev in /sys/bus/usb/devices/*/product; do \
    dir=$(dirname $dev); \
    echo "  $(basename $dir): $(cat $dev 2>/dev/null)"; \
done && \
echo "" && \
echo "=== xrandr ===" && \
XRANDR=$(find /home/deck/.local/share/Steam -name "xrandr" -type f 2>/dev/null | grep soldier_platform | head -1) && \
DISPLAY=:0 "$XRANDR" 2>/dev/null

# Check display-fix log
tail -20 /home/deck/.config/display-fix.log
```

---

## System Information

- **Device:** Steam Deck
- **OS:** SteamOS 3.x (Arch Linux based, kernel 6.11.11-valve26)
- **Desktop Environment:** KDE Plasma (X11)
- **GPU:** AMD Custom GPU 0932 (amdgpu driver)
- **Dock:** GenesysLogic USB3.1 Hub (05e3:0626)
- **Internal Display:** eDP, 800x1280 @ 90Hz
- **External Monitor:** DisplayPort-0, 1920x1080 @ 60Hz

---

## Related Documentation

- **Dual Display Setup:** `dual-display-setup-guide.md`
- **Audio/Video Troubleshooting:** `audio-video-troubleshooting-guide.md`
