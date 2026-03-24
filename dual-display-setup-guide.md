# Steam Deck Dual Display Setup Guide
**Date:** 2025-11-08
**Issue:** Could only use external monitor, not both displays simultaneously

---

## What Was The Issue?

### Problem
After fixing the display switching loop, the system was configured to use **only the external monitor** with the internal Steam Deck display turned OFF.

### Configuration State
- **Internal Display (eDP):** Disabled
- **External Monitor (DisplayPort-0):** Enabled and primary
- **Result:** Single display mode only

---

## How It Was Fixed

### The Solution
The `display-fix.sh` script was configured for single-display mode. We simply switched it to dual-display mode by enabling both screens.

### Steps Taken

1. **Located the display configuration script:**
   ```bash
   cat /home/deck/.config/display-fix.sh
   ```

2. **Identified the issue:**
   - Line 18 had: `--output eDP --off` (internal display OFF)
   - Line 21 had the dual-display config commented out

3. **Modified the script** to enable both displays:
   ```bash
   # Changed from:
   DISPLAY=:0 "$XRANDR" --output DisplayPort-0 --mode 1920x1080 --rate 60 --primary --output eDP --off

   # To (with right rotation for internal display - 90 degrees clockwise):
   DISPLAY=:0 "$XRANDR" --output DisplayPort-0 --mode 1920x1080 --rate 60 --primary --output eDP --mode 800x1280 --rate 90 --rotate right --left-of DisplayPort-0
   ```

4. **Applied the configuration immediately:**
   ```bash
   /home/deck/.config/display-fix.sh
   ```

5. **Verified both displays are active:**
   ```bash
   cat /sys/class/drm/card0-eDP-1/enabled    # Output: enabled
   cat /sys/class/drm/card0-DP-1/enabled     # Output: enabled
   ```

---

## Current Display Configuration

### Display Layout
```
┌──────────────┐  ┌─────────────────────────┐
│              │  │                         │
│   Steam      │  │   External Monitor      │
│   Deck       │  │   (Primary)             │
│   Screen     │  │   1920x1080 @ 60Hz      │
│  (Inverted)  │  │                         │
│ 800x1280     │  │                         │
│ @ 90Hz       │  │                         │
└──────────────┘  └─────────────────────────┘
    (Left)              (Right - Primary)
```

### Technical Details
- **Total Screen Space:** 2200 x 1080 pixels (after rotation)
- **Internal Display:** 800x1280 @ 90Hz at position 0+0 (rotated right/90° clockwise, appears as 1280x800)
- **External Monitor:** 1920x1080 @ 60Hz at position 1280+0 (primary)
- **Primary Display:** External monitor (most windows open here by default)

---

## Switching Between Display Modes

You can easily switch between dual-display and single-display modes by editing the script.

### To Use BOTH Displays (Current Setup)
Edit `/home/deck/.config/display-fix.sh` and ensure this line is active:
```bash
DISPLAY=:0 "$XRANDR" --output DisplayPort-0 --mode 1920x1080 --rate 60 --primary --output eDP --mode 800x1280 --rate 90 --rotate right --left-of DisplayPort-0
```

### To Use EXTERNAL MONITOR ONLY
Edit `/home/deck/.config/display-fix.sh` and change to:
```bash
DISPLAY=:0 "$XRANDR" --output DisplayPort-0 --mode 1920x1080 --rate 60 --primary --output eDP --off
```

### To Use INTERNAL DISPLAY ONLY
Edit `/home/deck/.config/display-fix.sh` and change to:
```bash
DISPLAY=:0 "$XRANDR" --output eDP --mode 800x1280 --rate 90 --primary --output DisplayPort-0 --off
```

### Apply Changes
After editing, run:
```bash
/home/deck/.config/display-fix.sh
```

Or simply unplug and replug your monitor (the script runs automatically on connection).

---

## Quick Reference Commands

### Check Display Status
```bash
# Check what displays are connected and their configuration
DISPLAY=:0 /home/deck/.local/share/Steam/steamapps/common/SteamLinuxRuntime_soldier/soldier_platform_2.0.20250826.159137/files/bin/xrandr

# Check if internal display is enabled
cat /sys/class/drm/card0-eDP-1/enabled

# Check if external monitor is enabled
cat /sys/class/drm/card0-DP-1/enabled

# Check external monitor connection status
cat /sys/class/drm/card0-DP-1/status
```

### Manually Configure Displays
```bash
# Store xrandr path for convenience
XRANDR="/home/deck/.local/share/Steam/steamapps/common/SteamLinuxRuntime_soldier/soldier_platform_2.0.20250826.159137/files/bin/xrandr"

# Dual display mode (with right rotation - 90° clockwise)
DISPLAY=:0 "$XRANDR" --output DisplayPort-0 --mode 1920x1080 --rate 60 --primary --output eDP --mode 800x1280 --rate 90 --rotate right --left-of DisplayPort-0

# External only
DISPLAY=:0 "$XRANDR" --output DisplayPort-0 --mode 1920x1080 --rate 60 --primary --output eDP --off

# Internal only (when monitor disconnected)
DISPLAY=:0 "$XRANDR" --output eDP --mode 800x1280 --rate 90 --primary --output DisplayPort-0 --off
```

### Edit Display Script
```bash
# Edit the script
nano /home/deck/.config/display-fix.sh

# Make it executable (if needed)
chmod +x /home/deck/.config/display-fix.sh

# Run the script manually
/home/deck/.config/display-fix.sh
```

---

## Display Position Options

You can arrange displays in different positions by changing the xrandr positioning flags:

### Internal Display Positions Relative to External Monitor

**Left of external (current setup with left rotation):**
```bash
--output eDP --mode 800x1280 --rate 90 --rotate left --left-of DisplayPort-0
```

**Right of external:**
```bash
--output eDP --mode 800x1280 --rate 90 --rotate left --right-of DisplayPort-0
```

**Above external:**
```bash
--output eDP --mode 800x1280 --rate 90 --rotate left --above DisplayPort-0
```

**Below external:**
```bash
--output eDP --mode 800x1280 --rate 90 --rotate left --below DisplayPort-0
```

**Mirror mode (same content on both):**
```bash
--output eDP --mode 800x1280 --rate 90 --rotate left --same-as DisplayPort-0
```

### Rotation Options for Internal Display

The `--rotate` flag supports these values:
- **normal**: Standard orientation (right-side up)
- **inverted**: Upside down (180 degrees)
- **left**: Rotated 90 degrees counterclockwise
- **right**: Rotated 90 degrees clockwise - **Current setup**

---

## Troubleshooting

### Problem: Only one display showing
**Solution:** Run the display script manually:
```bash
/home/deck/.config/display-fix.sh
```

### Problem: Displays in wrong position
**Solution:** Edit `/home/deck/.config/display-fix.sh` and change the positioning flag (e.g., `--left-of`, `--right-of`, `--above`, `--below`).

### Problem: Internal display showing upside down
**Solution:** The Steam Deck display is rotated by default. The script handles this automatically with the correct resolution (800x1280 instead of 1280x800).

### Problem: External monitor shows "No Signal"
**Solution:**
1. Check connection: `cat /sys/class/drm/card0-DP-1/status` (should show "connected")
2. Try a different cable
3. Try a different port on your dock (if using one)

### Problem: Configuration resets after reboot
**Solution:** The autostart script should handle this automatically. If not, check:
```bash
ls -la /home/deck/.config/autostart/display-fix.desktop
chmod +x /home/deck/.config/display-fix.sh
```

### Problem: Display switching loop returns
**Solution:** KScreen may have re-enabled itself. Disable it again:
```bash
systemctl --user mask plasma-kscreen.service
pkill -9 kscreen
```

---

## Advanced: Different External Monitor Resolutions

If your external monitor supports different resolutions, you can change them in the script.

### Common Resolution Options

**1080p (Full HD):**
```bash
--output DisplayPort-0 --mode 1920x1080 --rate 60
```

**1440p (2K):**
```bash
--output DisplayPort-0 --mode 2560x1440 --rate 60
```

**4K (Ultra HD):**
```bash
--output DisplayPort-0 --mode 3840x2160 --rate 60
```

**1080p at higher refresh rate (if supported):**
```bash
--output DisplayPort-0 --mode 1920x1080 --rate 144
```

### Find Available Resolutions
```bash
DISPLAY=:0 /home/deck/.local/share/Steam/steamapps/common/SteamLinuxRuntime_soldier/soldier_platform_2.0.20250826.159137/files/bin/xrandr | grep DisplayPort-0 -A 10
```

---

## Useful Bash Aliases

Add these to your `~/.bashrc` for quick access:

```bash
# Display management aliases
alias xr='/home/deck/.local/share/Steam/steamapps/common/SteamLinuxRuntime_soldier/soldier_platform_2.0.20250826.159137/files/bin/xrandr'
alias display-status='DISPLAY=:0 xr'
alias display-fix='/home/deck/.config/display-fix.sh'
alias display-edit='nano /home/deck/.config/display-fix.sh'

# Quick display mode switches
alias display-dual='DISPLAY=:0 xr --output DisplayPort-0 --mode 1920x1080 --rate 60 --primary --output eDP --mode 800x1280 --rate 90 --rotate left --left-of DisplayPort-0'
alias display-external='DISPLAY=:0 xr --output DisplayPort-0 --mode 1920x1080 --rate 60 --primary --output eDP --off'
alias display-internal='DISPLAY=:0 xr --output eDP --mode 800x1280 --rate 90 --primary --output DisplayPort-0 --off'

# Display info
alias display-check='echo "Internal Display:" && cat /sys/class/drm/card0-eDP-1/enabled && echo "External Monitor:" && cat /sys/class/drm/card0-DP-1/enabled && cat /sys/class/drm/card0-DP-1/status'
```

After adding these, reload your shell:
```bash
source ~/.bashrc
```

Then you can simply type:
- `display-dual` - Enable both displays
- `display-external` - External monitor only
- `display-internal` - Internal display only
- `display-check` - Check display status
- `display-status` - Show detailed display configuration

---

## Related Documentation

- **Audio Troubleshooting:** [audio-video-troubleshooting-guide.md](audio-video-troubleshooting-guide.md)

---

## System Information

- **Device:** Steam Deck
- **OS:** SteamOS 3.x (Arch Linux based)
- **Desktop Environment:** KDE Plasma
- **Display Server:** X11
- **Internal Display:** 800x1280 @ 90Hz (eDP)
- **External Monitor:** 1920x1080 @ 60Hz (DisplayPort-0)

---

## Quick Summary

| Action | Command |
|--------|---------|
| Enable both displays | `display-dual` (after adding aliases) or run `/home/deck/.config/display-fix.sh` |
| Check display status | `cat /sys/class/drm/card0-eDP-1/enabled && cat /sys/class/drm/card0-DP-1/enabled` |
| Edit configuration | `nano /home/deck/.config/display-fix.sh` |
| Apply changes | `/home/deck/.config/display-fix.sh` |
| View current setup | `DISPLAY=:0 xrandr` (full path needed) |

---

**Created with Claude Code** - Your AI-powered terminal assistant

For more help: `claude` in terminal or visit https://docs.claude.com/
