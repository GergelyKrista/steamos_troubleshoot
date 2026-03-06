# Audio & Video Troubleshooting Guide
**Date:** 2025-11-08
**Issue:** No sound from Bluetooth headphones + Videos constantly loading on websites

---

## What Was The Issue?

### Primary Problem
The Bluetooth headphones (Sony WH-1000XM5) were connected but in a **"suspended" state** with an inactive Bluetooth audio transport. This caused:
- No audio output to the headphones
- Video players hanging/buffering indefinitely (because they couldn't initialize audio)
- System unable to use any audio input/output devices

### Technical Details
```
Bluetooth Device: WH-1000XM5 (88:C9:E8:9C:7F:4E)
State: suspended
Bluetooth Transport: empty/inactive
Codec: LDAC
Profile: a2dp-sink
```

The PipeWire audio system showed the device as default but couldn't actually route audio to it because the Bluetooth transport layer was not active.

---

## How It Was Fixed

### Step 1: Diagnosed the Audio System
```bash
# Checked PipeWire audio services (all running)
systemctl --user status pipewire pipewire-pulse wireplumber

# Listed audio devices
pw-cli list-objects | grep -E "(WH-1000XM5|node.name)"

# Checked default audio routing
pw-metadata -n default
```

### Step 2: Found the Suspended State
```bash
# Inspected the Bluetooth headphones node
pw-cli info 91

# Output showed:
# state: "suspended"
# api.bluez5.transport = ""  (empty = not active)
```

### Step 3: Restarted Audio Services
```bash
systemctl --user restart pipewire pipewire-pulse wireplumber
```

This caused the Bluetooth headphones to disconnect (expected behavior when audio services restart).

### Step 4: Reconnected Bluetooth Headphones
- Opened Steam Deck Quick Access menu (`...` button)
- Settings → Bluetooth
- Clicked on WH-1000XM5 to reconnect
- Audio and video playback restored

---

## If This Happens Again - Quick Fix

### Option 1: Quick Bluetooth Reconnect (Try First)
1. Press `...` button on Steam Deck
2. Settings → Bluetooth
3. Click your headphones to reconnect

### Option 2: Restart Audio Services
```bash
# Run this command in terminal
systemctl --user restart pipewire pipewire-pulse wireplumber

# Then reconnect Bluetooth headphones from UI
```

### Option 3: Force Audio Transport with Test Tone (Most Reliable)
Sometimes after reconnecting, the Bluetooth transport stays in "suspended" state with an empty transport even though the device appears connected. Playing a test tone directly to the headphones forces the transport to activate.

```bash
# Step 1: Set Bluetooth headphones as default sink
pw-metadata -n default 0 default.audio.sink '{"name":"bluez_output.88_C9_E8_9C_7F_4E.1"}'

# Step 2: Generate a test tone WAV file
python3 -c "
import struct, math, wave
rate = 48000
with wave.open('/tmp/test_tone.wav', 'w') as f:
    f.setnchannels(2)
    f.setsampwidth(2)
    f.setframerate(rate)
    for i in range(rate):
        val = int(32767 * 0.5 * math.sin(2 * math.pi * 440 * i / rate))
        f.writeframes(struct.pack('<hh', val, val))
"

# Step 3: Play the test tone to the Bluetooth headphones (target 193 = WH-1000XM5)
# Find the target ID with: pw-play --list-targets
pw-play --target 193 /tmp/test_tone.wav
```

You should hear a short beep and the Bluetooth transport will become active. All other audio (Citrix, browser, etc.) will then route through the headphones.

### Option 4: Full Bluetooth Reset
```bash
# Turn off headphones completely
# In Steam Deck: Settings → Bluetooth → Forget device
# Turn headphones back on in pairing mode
# Re-pair with Steam Deck
```

---

## Diagnostic Commands Reference

### Check Audio System Status
```bash
# Check if audio services are running
systemctl --user status pipewire pipewire-pulse wireplumber

# List all audio devices
pw-cli list-objects Node | grep -E "(node.name|node.description|media.class)"

# Check default audio device
pw-metadata -n default

# Get detailed info on specific device (replace <id> with device ID)
pw-cli info <id>
```

### Check Bluetooth Status
```bash
# Check Bluetooth daemon is running
ps aux | grep bluetooth

# List available Bluetooth tools
which bluetoothctl rfkill
```

### Check Network (if videos not loading)
```bash
# Test basic connectivity
ping -c 3 8.8.8.8

# Test DNS resolution
ping -c 2 google.com

# Test HTTPS to video site
curl -I --max-time 5 https://www.youtube.com

# Check DNS config
cat /etc/resolv.conf

# Check network routing
ip route show
```

### Check System Resources
```bash
# Check if system is overloaded
top -b -n 1 | head -20

# Check audio processes
ps aux | grep -E 'pipewire|pulseaudio|wireplumber' | grep -v grep
```

---

## Understanding PipeWire Audio on Steam Deck

### What is PipeWire?
PipeWire is the modern audio/video routing system on Steam Deck. It replaced PulseAudio and provides:
- Low-latency audio
- Better Bluetooth support
- Professional audio routing

### Key Components
- **pipewire**: Core audio server
- **pipewire-pulse**: PulseAudio compatibility layer
- **wireplumber**: Session manager (handles routing/policy)

### Common States
- **running**: Device is active and playing audio
- **suspended**: Device is connected but not streaming (sleeping)
- **idle**: Device is available but not in use

---

## AI CLI Tools for Troubleshooting

### 1. Claude Code (Current Tool)
```bash
# Launch Claude Code
claude

# Common commands
/help              # Get help
/clear             # Clear conversation
```

**Use Cases:**
- Complex multi-step troubleshooting
- System diagnostics
- Automated problem solving
- Documentation generation

### 2. Quick Audio Commands
```bash
# Create an alias for quick audio restart (add to ~/.bashrc)
alias fix-audio='systemctl --user restart pipewire pipewire-pulse wireplumber'

# Then just run:
fix-audio
```

### 3. Audio Device Shortcuts
```bash
# List all audio sinks (outputs)
alias list-audio='pw-cli list-objects Node | grep -E "(node.name|node.description|media.class)"'

# Check what's playing
alias audio-status='pw-metadata -n default'

# Show detailed audio info
alias audio-debug='systemctl --user status pipewire pipewire-pulse wireplumber && pw-metadata -n default'
```

### 4. System Health Check
```bash
# One-liner to check audio + network + resources
alias health-check='echo "=== AUDIO ===" && systemctl --user status pipewire | grep Active && echo -e "\n=== NETWORK ===" && ping -c 2 8.8.8.8 && echo -e "\n=== RESOURCES ===" && top -b -n 1 | head -5'
```

---

## When to Use Each Solution

### Bluetooth Headphones No Sound
1. Try reconnecting from UI first
2. If that fails, restart audio services
3. If transport stays suspended, force it with a test tone (Option 3 above)
4. If still failing, do full Bluetooth reset

### Videos Not Loading on Websites
1. Check if audio is working first (play a local file)
2. If no audio, fix audio first (see above)
3. If audio works but videos still hang, check network
4. Clear browser cache/cookies

### System Feels Slow
1. Check `top` for CPU/memory usage
2. Close unnecessary applications
3. Restart Steam Deck if needed

### No Audio Input/Output Devices Available
1. Restart audio services: `systemctl --user restart pipewire pipewire-pulse wireplumber`
2. Check if services are running: `systemctl --user status pipewire`
3. Check logs: `journalctl --user -u pipewire -u wireplumber --since "10 minutes ago"`

---

## Prevention Tips

1. **Don't force-quit audio applications** - Let them close gracefully
2. **Keep Bluetooth headphones charged** - Low battery can cause connection issues
3. **Update Steam Deck regularly** - Audio stack improvements are ongoing
4. **Limit simultaneous audio apps** - Too many can cause routing conflicts

---

## Additional Resources

- **Steam Deck Documentation**: https://help.steampowered.com/
- **PipeWire Wiki**: https://gitlab.freedesktop.org/pipewire/pipewire/-/wikis/home
- **Arch Wiki (Steam Deck uses Arch)**: https://wiki.archlinux.org/title/PipeWire

---

## Quick Reference Card

| Problem | Quick Fix |
|---------|-----------|
| No Bluetooth audio | Reconnect, then play test tone: `pw-play --target 193 /tmp/test_tone.wav` |
| Videos won't load | Fix audio first, then test network |
| No audio devices | `systemctl --user restart pipewire pipewire-pulse wireplumber` |
| System slow | Check `top`, close apps, restart if needed |
| Bluetooth won't connect | Forget device, re-pair from scratch |

---

**Created with Claude Code** - Your AI-powered terminal assistant

For more help: `claude` in terminal or visit https://docs.claude.com/
