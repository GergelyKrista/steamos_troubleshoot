# Citrix Workspace Guide for Steam Deck/Linux

## Quick Start (Recommended Method - Via Browser)

Since the native Citrix Workspace app has authentication issues on your system, use the browser method:

1. **Open your web browser**
2. **Navigate to your Citrix portal:**
   ```
   https://rbsconnect.rbspeople.com
   ```
3. **Log in with your credentials**
4. **Click on your desired application or desktop**
5. **Download the .ica file** (it will save to ~/Downloads)
6. **Open the .ica file with this command:**
   ```bash
   /opt/Citrix/ICAClient/wfica ~/Downloads/*.ica
   ```

## Alternative Methods

### Method 1: Try Native Citrix Workspace App
```bash
# Start Citrix Workspace
/opt/Citrix/ICAClient/selfservice

# If it hangs during login, press ESC and use the browser method instead
```

### Method 2: Direct ICA Client
```bash
# If you already have an .ica file
/opt/Citrix/ICAClient/wfica /path/to/your/file.ica
```

## Troubleshooting

### If Citrix Won't Start
```bash
# Kill any stuck Citrix processes
killall selfservice wfica PrimaryAuthManager AuthManSvr 2>/dev/null

# Clear cache and try again
rm -rf ~/.ICAClient/cache/* ~/.ICAClient/.tmp/*

# Restart Citrix
/opt/Citrix/ICAClient/selfservice
```

### If Authentication Hangs (Common Issue)
This is a known issue with SAML authentication in Citrix Workspace on Linux. The workaround is:

1. Close the stuck authentication window (press ESC or click X)
2. Use the browser method described above
3. The browser handles authentication better than the native app

### Clear All Citrix Data (Nuclear Option)
```bash
# Only if nothing else works
rm -rf ~/.ICAClient
killall selfservice wfica PrimaryAuthManager AuthManSvr 2>/dev/null
```

## Creating a Desktop Shortcut

Create a script to quickly launch Citrix from downloaded .ica files:

```bash
# Create the script
cat > ~/Desktop/launch_citrix.sh << 'EOF'
#!/bin/bash
# Find the most recent .ica file in Downloads
ICA_FILE=$(ls -t ~/Downloads/*.ica 2>/dev/null | head -1)

if [ -z "$ICA_FILE" ]; then
    echo "No .ica file found in Downloads"
    echo "Please download one from https://rbsconnect.rbspeople.com"
    xdg-open https://rbsconnect.rbspeople.com
else
    echo "Launching: $ICA_FILE"
    /opt/Citrix/ICAClient/wfica "$ICA_FILE"
fi
EOF

# Make it executable
chmod +x ~/Desktop/launch_citrix.sh
```

## Daily Workflow

1. **Open browser and go to:** https://rbsconnect.rbspeople.com
2. **Log in and download the .ica file for your session**
3. **Run this command:**
   ```bash
   /opt/Citrix/ICAClient/wfica ~/Downloads/*.ica
   ```

Or if you created the desktop shortcut, just double-click `launch_citrix.sh`

## Important Notes

- The native Citrix Workspace app (`selfservice`) has issues with SAML/SSO authentication on Linux
- The browser method bypasses these issues by handling auth in the browser
- Downloaded .ica files are session-specific and may expire
- You may need to re-download the .ica file for each new session
- The .ica files contain your session tokens, so they're temporary

## Checking Citrix Logs (If Needed)

If you need to troubleshoot:
```bash
# View latest authentication log
tail -f ~/.ICAClient/logs/PrimaryAuthManager.latest

# Check for errors
grep -i error ~/.ICAClient/logs/*.log
```

## Network Requirements

Ensure your network allows:
- HTTPS access to your Citrix gateway (port 443)
- ICA protocol (usually port 1494 or 2598)
- No VPN conflicts that might block Citrix traffic

---

**Last Updated:** November 3, 2025
**Citrix Server:** rbsconnect.rbspeople.com
**Installation Path:** /opt/Citrix/ICAClient/