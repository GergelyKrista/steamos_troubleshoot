# Citrix Workspace Guide for Steam Deck

## Quick Start (Browser Method — Recommended)

The native Citrix Workspace app has authentication issues with SAML/SSO on Linux. Use the browser method instead:

1. Open your web browser and navigate to your Citrix portal
2. Log in with your credentials
3. Click on your desired application or desktop
4. Download the `.ica` file (saves to `~/Downloads/`)
5. Launch it:
   ```bash
   /opt/Citrix/ICAClient/wfica ~/Downloads/*.ica
   ```

> **Tip:** To launch the most recent ICA file automatically:
> ```bash
> /opt/Citrix/ICAClient/wfica "$(ls -t ~/Downloads/*.ica | head -1)"
> ```

## Prerequisites

- Citrix Workspace app installed at `/opt/Citrix/ICAClient/`
- An ICA file downloaded from your Citrix web portal
- Steam Deck in Desktop Mode (not Gaming Mode)

## Alternative Launch Methods

### Native Citrix Workspace App

```bash
# Start Citrix Workspace
/opt/Citrix/ICAClient/selfservice

# If it hangs during login, press ESC and use the browser method instead
```

### Direct ICA Client

```bash
# Launch a specific ICA file
/opt/Citrix/ICAClient/wfica ~/Downloads/[YOUR_ICA_FILE].ica &
```

The `&` at the end runs it in background so you can close the terminal.

### File Manager (GUI)

1. Open Dolphin and navigate to `~/Downloads/`
2. Right-click the `.ica` file → "Open With" → "Other Application"
3. Enter command: `/opt/Citrix/ICAClient/wfica`
4. Check "Remember application association" if available

## Create a Quick Launch Script

```bash
cat > ~/Desktop/launch-citrix.sh << 'SCRIPT'
#!/bin/bash
# Find the most recent .ica file in Downloads
ICA_FILE=$(ls -t ~/Downloads/*.ica 2>/dev/null | head -1)

if [ -z "$ICA_FILE" ]; then
    echo "No .ica file found in Downloads"
    echo "Please download one from your Citrix web portal"
    xdg-open https://your-citrix-portal.example.com
else
    echo "Launching: $ICA_FILE"
    /opt/Citrix/ICAClient/wfica "$ICA_FILE" &
fi
SCRIPT
chmod +x ~/Desktop/launch-citrix.sh
```

## Browser Integration

### Chrome/Chromium
1. When downloading an ICA file, the browser may ask "Open with application?"
2. Choose `/opt/Citrix/ICAClient/wfica`
3. Check "Always open files of this type"

### Firefox
1. Go to Settings → General → Applications
2. Find "Citrix ICA file" or `application/x-ica`
3. Set action to: `/opt/Citrix/ICAClient/wfica`

## Troubleshooting

### Citrix Won't Start
```bash
# Kill any stuck Citrix processes
killall selfservice wfica PrimaryAuthManager AuthManSvr 2>/dev/null

# Clear cache and try again
rm -rf ~/.ICAClient/cache/* ~/.ICAClient/.tmp/*

# Restart Citrix
/opt/Citrix/ICAClient/selfservice
```

### Authentication Hangs (Common Issue)
This is a known issue with SAML authentication in Citrix Workspace on Linux:
1. Close the stuck authentication window (press ESC or click X)
2. Use the browser method described above
3. The browser handles authentication better than the native app

### "Command not found" Error
```bash
# Verify Citrix is installed
ls /opt/Citrix/ICAClient/
```

### ICA File Not Opening
- Check file permissions: `ls -la ~/Downloads/*.ica`
- Ensure file is not corrupted (should be ~1–2KB)
- Download a fresh ICA file — they expire after 24–48 hours

### Session Disconnects Immediately
- Check internet connection
- Verify credentials are saved correctly
- Try downloading a fresh ICA file

### GTK Module Warnings
The warning "Failed to load module canberra-gtk-module" is harmless. The application still works.

### Clear All Citrix Data (Nuclear Option)
```bash
# Only if nothing else works
rm -rf ~/.ICAClient
killall selfservice wfica PrimaryAuthManager AuthManSvr 2>/dev/null
```

## Useful Commands

| Task | Command |
|------|---------|
| Launch most recent ICA | `/opt/Citrix/ICAClient/wfica "$(ls -t ~/Downloads/*.ica \| head -1)" &` |
| Launch specific ICA | `/opt/Citrix/ICAClient/wfica ~/Downloads/[filename].ica &` |
| List all ICA files | `ls -la ~/Downloads/*.ica` |
| Delete all ICA files | `rm ~/Downloads/*.ica` |
| Check Citrix process | `pgrep -l wfica` |
| Kill stuck sessions | `killall wfica selfservice` |
| Check Citrix version | `/opt/Citrix/ICAClient/wfica -version` |
| View Citrix logs | `cat ~/.ICAClient/logs/*.log` |

## Viewing Logs

```bash
# View latest authentication log
tail -f ~/.ICAClient/logs/PrimaryAuthManager.latest

# Check for errors
grep -i error ~/.ICAClient/logs/*.log
```

## Network Requirements

Ensure your network allows:
- HTTPS access to your Citrix gateway (port 443)
- ICA protocol (port 1494 or 2598)
- No VPN conflicts that might block Citrix traffic

## Important Notes

- `xdg-open` may not work reliably on SteamOS for ICA files — use `wfica` directly
- ICA files are single-use session tokens; download a fresh one each time
- The native `selfservice` app has issues with SAML/SSO; prefer the browser method
- ICA files contain connection info but **not** passwords — they're safe to delete

---

**Installation Path:** `/opt/Citrix/ICAClient/`
**Last Updated:** March 2026
