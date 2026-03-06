# Citrix Workspace ICA File Launch Guide

## Overview
This guide explains how to launch Citrix Workspace sessions from ICA files downloaded through your web browser on Steam Deck/Linux.

## Prerequisites
- Citrix Workspace app must be installed at `/opt/Citrix/ICAClient/`
- ICA file downloaded from your Citrix web portal (usually saved in `~/Downloads/`)

## Step-by-Step Instructions

### Method 1: Manual Launch from Terminal

1. **Open Terminal**
   - Press `CTRL + ALT + T` or open Konsole from the application menu

2. **Navigate to Downloads folder** (optional)
   ```bash
   cd ~/Downloads
   ```

3. **List ICA files to confirm the filename**
   ```bash
   ls -la *.ica
   ```
   You should see files like: `VkNTZURhYVMuVkNTZSBQcm9kdWN0aW9uICRQMTAzOTI-.ica`

4. **Launch the ICA file with Citrix**
   ```bash
   /opt/Citrix/ICAClient/wfica ~/Downloads/[YOUR_ICA_FILE].ica &
   ```

   Example:
   ```bash
   /opt/Citrix/ICAClient/wfica ~/Downloads/VkNTZURhYVMuVkNTZSBQcm9kdWN0aW9uICRQMTAzOTI-.ica &
   ```

   Note: The `&` at the end runs it in background, allowing you to close the terminal

### Method 2: Create a Quick Launch Script

1. **Create a launcher script**
   ```bash
   nano ~/development/launch-citrix.sh
   ```

2. **Add this content to the script:**
   ```bash
   #!/bin/bash
   # Citrix ICA Launcher Script

   # Find the most recent ICA file in Downloads
   ICA_FILE=$(ls -t ~/Downloads/*.ica 2>/dev/null | head -1)

   if [ -z "$ICA_FILE" ]; then
       echo "No ICA file found in Downloads folder"
       exit 1
   fi

   echo "Launching: $ICA_FILE"
   /opt/Citrix/ICAClient/wfica "$ICA_FILE" &
   ```

3. **Make the script executable**
   ```bash
   chmod +x ~/development/launch-citrix.sh
   ```

4. **Run the script anytime**
   ```bash
   ~/development/launch-citrix.sh
   ```

### Method 3: Using File Manager (GUI)

1. **Open your file manager** (Dolphin on Steam Deck)
2. **Navigate to Downloads folder**
3. **Right-click on the ICA file**
4. **Select "Open With" → "Other Application"**
5. **Enter command:** `/opt/Citrix/ICAClient/wfica`
6. **Check "Remember application association"** (if available)
7. **Click OK**

## Troubleshooting

### Common Issues and Solutions

1. **"Command not found" error**
   - Verify Citrix is installed: `ls /opt/Citrix/ICAClient/`
   - If not installed, download from Citrix website

2. **ICA file not opening**
   - Check file permissions: `ls -la ~/Downloads/*.ica`
   - Ensure file is not corrupted (should be ~1-2KB in size)

3. **Session disconnects immediately**
   - Check internet connection
   - Verify credentials are saved correctly
   - Try downloading a fresh ICA file

4. **GTK Module warnings**
   - These warnings (like "Failed to load module canberra-gtk-module") are harmless
   - The application will still work despite these messages

### Useful Commands

**Check if Citrix is running:**
```bash
ps aux | grep -i citrix
```

**Kill stuck Citrix sessions:**
```bash
killall wfica
killall selfservice
```

**View Citrix logs:**
```bash
cat ~/.ICAClient/logs/*.log
```

**Check Citrix version:**
```bash
/opt/Citrix/ICAClient/wfica -version
```

## Browser Integration Tips

### For Chrome/Chromium:
1. When downloading ICA file, browser may ask "Open with application?"
2. Choose `/opt/Citrix/ICAClient/wfica` as the application
3. Check "Always open files of this type"

### For Firefox:
1. Go to Settings → General → Applications
2. Find "Citrix ICA file" or "application/x-ica"
3. Set action to: `/opt/Citrix/ICAClient/wfica`

## Security Notes
- ICA files contain connection information but NOT passwords
- Delete old ICA files periodically: `rm ~/Downloads/*.ica`
- ICA files expire after a certain time (usually 24-48 hours)

## Quick Reference

| Task | Command |
|------|---------|
| Launch most recent ICA | `/opt/Citrix/ICAClient/wfica $(ls -t ~/Downloads/*.ica \| head -1) &` |
| Launch specific ICA | `/opt/Citrix/ICAClient/wfica ~/Downloads/[filename].ica &` |
| List all ICA files | `ls -la ~/Downloads/*.ica` |
| Delete all ICA files | `rm ~/Downloads/*.ica` |
| Check Citrix process | `pgrep -l wfica` |

## Additional Resources
- [Citrix Workspace for Linux Documentation](https://docs.citrix.com/en-us/citrix-workspace-app-for-linux)
- ICA files are temporary session files - always download fresh from your Citrix portal
- For persistent connections, consider saving connection settings in Citrix Workspace app itself

---
*Last updated: November 2024*
*Platform: Steam Deck / Linux*