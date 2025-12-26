# Scrcpy GUI - Troubleshooting Guide

Common issues, solutions, and debugging tips for the Scrcpy GUI application.

## Table of Contents

1. [Device Connection Issues](#device-connection-issues)
2. [Wireless Connection Problems](#wireless-connection-problems)
3. [Application Issues](#application-issues)
4. [Scrcpy Execution Problems](#scrcpy-execution-problems)
5. [Performance Issues](#performance-issues)
6. [Platform-Specific Issues](#platform-specific-issues)
7. [Error Messages](#error-messages)
8. [Diagnostic Tools](#diagnostic-tools)

---

## Device Connection Issues

### Device Not Detected

**Symptoms:**
- Device selector shows "No device selected"
- Device doesn't appear after plugging in
- "Waiting for devices..." message persists

**Solutions:**

1. **Check USB Debugging**
   ```
   - Go to Settings → Developer Options → USB Debugging
   - Toggle it off and on again
   - Accept the "Allow USB debugging" prompt on device
   - Check "Always allow from this computer"
   ```

2. **Verify ADB Connection**
   ```bash
   # Open terminal/command prompt
   adb devices

   # Expected output:
   List of devices attached
   ABC123DEF456    device
   ```

   If you see:
   - **`unauthorized`** → Accept prompt on device
   - **`offline`** → Restart device or ADB server
   - **No devices** → Check cable/drivers

3. **Restart ADB Server**
   ```bash
   adb kill-server
   adb start-server
   adb devices
   ```

4. **Check USB Cable**
   - Use a different USB cable (some are charge-only)
   - Try a different USB port
   - Avoid USB hubs, connect directly to computer

5. **Windows: Update Drivers**
   - Open Device Manager
   - Find your Android device (may be under "Other devices")
   - Right-click → Update Driver
   - Choose "Search automatically for drivers"

6. **Revoke and Re-authorize**
   ```bash
   # On device
   Settings → Developer Options → Revoke USB debugging authorizations

   # Reconnect and accept new prompt
   ```

---

### Device Shows as "unauthorized"

**Cause:** USB debugging not authorized on device

**Solution:**
1. Check device screen for authorization prompt
2. Tap "Always allow from this computer"
3. Tap "OK" or "Allow"
4. If no prompt appears:
   ```bash
   adb kill-server
   adb start-server
   ```
5. Disconnect and reconnect USB cable

---

### Device Shows as "offline"

**Cause:** ADB connection lost or device rebooted

**Solutions:**

1. **Quick Fix:**
   ```bash
   adb reconnect
   # or
   adb disconnect
   adb devices  # Will auto-reconnect
   ```

2. **Full Reset:**
   ```bash
   adb kill-server
   # Disconnect USB cable
   # Wait 5 seconds
   # Reconnect USB cable
   adb start-server
   adb devices
   ```

3. **Device Reboot:**
   - Reboot your Android device
   - Wait for full startup
   - Reconnect USB cable

---

## Wireless Connection Problems

### Wireless Connection Fails

**Symptoms:**
- "Connect Wirelessly" button doesn't work
- Connection timeout errors
- Device not appearing as IP:PORT

**Solutions:**

1. **Ensure Initial USB Connection**
   - Wireless setup REQUIRES initial USB connection
   - Connect via USB first
   - Then click "Connect Wirelessly"
   - Only disconnect USB after success message

2. **Verify Same Network**
   ```bash
   # On computer, find IP:
   # Windows:
   ipconfig

   # macOS/Linux:
   ifconfig

   # On device: Settings → About → Status → IP address
   # First 3 parts should match (e.g., 192.168.1.x)
   ```

3. **Check Firewall**
   - Allow incoming connections on port 5555
   - Windows: Allow ADB through Windows Firewall
   - macOS: System Preferences → Security → Firewall → Allow adb
   - Linux: Check iptables or ufw rules

4. **Manual Connection**
   ```bash
   # With device connected via USB:
   adb tcpip 5555

   # Find device IP (Settings → About → Status)
   adb connect 192.168.1.XXX:5555

   # Disconnect USB cable
   adb devices  # Should show IP:5555
   ```

5. **Router Configuration**
   - Disable AP Isolation if on guest network
   - Assign static IP to device
   - Check if port 5555 is blocked

---

### Wireless Connection Drops Frequently

**Causes:**
- WiFi signal strength
- Power saving modes
- Router issues

**Solutions:**

1. **Improve Signal Strength**
   - Move closer to router
   - Use 2.4GHz band (better range) instead of 5GHz
   - Reduce interference from other devices

2. **Disable Power Saving**
   ```
   Settings → Battery → Battery Optimization
   → Find "ADB" or "Shell" → Don't optimize

   Settings → WiFi → Advanced → Keep WiFi on during sleep → Always
   ```

3. **Use Static IP**
   - Assign static IP to device in router settings
   - Prevents IP changes on reconnect
   - More reliable connection

4. **Reconnect Command**
   ```bash
   adb connect <DEVICE_IP>:5555
   ```

---

## Application Issues

### App Won't Launch

**Symptoms:**
- Double-click does nothing
- Crash on startup
- White screen/blank window

**Solutions:**

1. **Check Flutter Installation** (if running from source)
   ```bash
   flutter doctor
   # Fix any issues shown
   ```

2. **Delete App Data**
   - Windows: Delete `%APPDATA%\ScrcpyGui\`
   - macOS/Linux: Delete `~/Documents/ScrcpyGui/`
   - Restart application

3. **Check Logs**
   - Windows: Check Event Viewer
   - macOS: Check Console.app
   - Linux: Check terminal output or syslog

4. **Reinstall**
   - Uninstall application
   - Delete app data folders
   - Reinstall from source or release

---

### Settings Not Saving

**Symptoms:**
- Panel customization resets on restart
- Paths reset to defaults
- Favorites disappear

**Solutions:**

1. **Check Permissions**
   - Ensure app has write access to documents folder
   - Windows: Run as administrator (temporary test)
   - macOS/Linux: Check folder permissions

2. **Verify Storage Location**
   ```bash
   # Windows
   dir %APPDATA%\ScrcpyGui\

   # macOS/Linux
   ls ~/Documents/ScrcpyGui/
   ```

3. **Manual File Check**
   - Look for `settings.json` and `commands.json`
   - Check if files are read-only
   - Try deleting and letting app recreate

---

### "Scrcpy Not Found" Error

**Symptoms:**
- Error message when clicking Run
- "scrcpy command not found"
- Path errors in settings

**Solutions:**

1. **Verify Installation**
   ```bash
   # Test in terminal
   scrcpy --version

   # Should show version number
   # Example: scrcpy 2.3.1
   ```

2. **Add to PATH**

   **Windows:**
   ```
   1. Search "Environment Variables"
   2. Edit "Path" variable
   3. Add scrcpy installation folder
   4. Restart app
   ```

   **macOS/Linux:**
   ```bash
   # Add to ~/.bashrc or ~/.zshrc
   export PATH="/path/to/scrcpy:$PATH"

   # Reload
   source ~/.bashrc
   ```

3. **Configure Path in App**
   - Go to Settings page
   - Set "Scrcpy Installation Path"
   - Point to folder containing scrcpy executable
   - Click Save

4. **Reinstall Scrcpy**
   ```bash
   # Windows (Scoop)
   scoop install scrcpy

   # macOS (Homebrew)
   brew install scrcpy

   # Linux (apt)
   sudo apt install scrcpy
   ```

---

## Scrcpy Execution Problems

### "Scrcpy Failed to Start"

**Symptoms:**
- Command generated but scrcpy doesn't launch
- Terminal window opens and closes immediately
- No mirror window appears

**Diagnostics:**

1. **Test Command Manually**
   - Copy generated command from app
   - Paste in terminal
   - Read error message

2. **Common Errors:**

   **"Device not found"**
   ```bash
   # Check device connection
   adb devices
   ```

   **"Encoder not found"**
   ```bash
   # Try different codec
   # In app: General panel → Video Codec → H.264
   ```

   **"Server installation failed"**
   ```bash
   # Update scrcpy
   scoop update scrcpy  # Windows
   brew upgrade scrcpy  # macOS
   sudo apt update && sudo apt upgrade scrcpy  # Linux
   ```

3. **Version Compatibility**
   ```bash
   scrcpy --version
   adb --version

   # Ensure both are up to date
   # Minimum scrcpy version: 2.0
   ```

---

### Video Codec Errors

**Symptoms:**
- "Encoder not found"
- "Codec not supported"
- Black screen but audio works

**Solutions:**

1. **Use Default Codec**
   - Clear Video Codec field in General panel
   - Let scrcpy auto-select

2. **Try Different Codecs**
   ```
   Test in this order:
   1. H.264 (most compatible)
   2. H.265
   3. AV1
   ```

3. **Check Device Support**
   ```bash
   adb shell dumpsys media.player | grep -i codec
   ```

4. **Reduce Quality**
   - Lower video bitrate (try 4M)
   - Reduce max-size (try 1280)

---

### Audio Not Working

**Symptoms:**
- Video works but no audio
- Audio codec errors
- Choppy/glitchy audio

**Solutions:**

1. **Check Scrcpy Version**
   - Audio requires scrcpy 2.0+
   - Update to latest version

2. **Test Basic Audio**
   ```bash
   scrcpy --audio-codec=opus --audio-bit-rate=128K
   ```

3. **Change Audio Source**
   - Try different sources in Audio panel
   - Default: "output"
   - Alternative: "playback"

4. **Increase Buffer**
   - Audio panel → Audio Buffer → 512 or 1024
   - Higher buffer = smoother audio, more latency

5. **Disable Audio (Temporary)**
   - Audio panel → No Audio checkbox
   - Use for troubleshooting video issues

---

## Performance Issues

### High Latency / Lag

**Symptoms:**
- Noticeable delay between action and screen update
- Sluggish input response
- Choppy video

**Solutions:**

1. **Use USB Connection**
   - Wireless has inherent latency
   - USB provides lowest latency

2. **Reduce Quality**
   ```
   General panel:
   - Video Bit Rate: 4M or 6M
   - Max Size: 1280
   ```

3. **Change Codec**
   - Try H.264 (lower CPU usage)
   - Disable H.265/AV1

4. **Close Background Apps**
   - On device: Close unused apps
   - On computer: Close heavy applications

5. **Disable Audio**
   - Audio panel → No Audio
   - Reduces bandwidth and CPU usage

6. **Network Optimization** (wireless only)
   - Use 5GHz WiFi if available
   - Reduce distance to router
   - Close bandwidth-heavy applications

---

### Frame Drops / Stuttering

**Symptoms:**
- Video freezes occasionally
- Inconsistent frame rate
- Jerky motion

**Solutions:**

1. **Limit Frame Rate**
   ```
   Recording panel → Max FPS: 30
   ```

2. **Reduce Resolution**
   ```
   General panel → Max Size: 1280 or 1920
   ```

3. **Check System Resources**
   - Task Manager (Windows) / Activity Monitor (macOS)
   - Ensure CPU/GPU not maxed out
   - Close resource-heavy applications

4. **Update Graphics Drivers**
   - NVIDIA, AMD, or Intel drivers
   - Can significantly improve performance

---

### High Battery Drain (Device)

**Symptoms:**
- Device battery depletes quickly
- Device getting hot
- Battery percentage drops fast

**Solutions:**

1. **Turn Screen Off**
   ```
   General panel → Screen Off checkbox
   ```

2. **Reduce Quality**
   - Lower bitrate
   - Lower resolution
   - Lower frame rate

3. **Use Wired Connection**
   - Wireless uses more battery
   - USB charges while connected

4. **Disable Unnecessary Features**
   - Turn off audio if not needed
   - Reduce screen brightness on device

---

## Platform-Specific Issues

### Windows-Specific

**Issue: ADB Device Drivers Not Installing**

**Solution:**
```
1. Download Universal ADB Drivers
2. Device Manager → Update Driver → Browse
3. Point to downloaded driver folder
4. Restart computer
```

**Issue: Terminal Window Closes Immediately**

**Solution:**
- Settings → Open commands in new terminal: ON
- Windows may be closing terminal too fast
- Try running command manually to see error

**Issue: Process Monitoring Shows No Information**

**Solution:**
```bash
# Ensure WMIC is accessible
wmic process where name="scrcpy.exe" get ProcessId
```

---

### macOS-Specific

**Issue: Permission Denied Errors**

**Solution:**
```bash
# Grant terminal access
System Preferences → Security & Privacy → Privacy → Full Disk Access
→ Add Terminal.app

# Fix permissions
chmod +x /usr/local/bin/adb
chmod +x /usr/local/bin/scrcpy
```

**Issue: scrcpy Installed But Not Found**

**Solution:**
```bash
# Homebrew path
which scrcpy
# If empty, add Homebrew to PATH
export PATH="/opt/homebrew/bin:$PATH"

# Add to ~/.zshrc for persistence
echo 'export PATH="/opt/homebrew/bin:$PATH"' >> ~/.zshrc
```

---

### Linux-Specific

**Issue: Terminal Emulator Not Detected**

**Solution:**
```bash
# Install a supported terminal
sudo apt install gnome-terminal  # GNOME
sudo apt install konsole  # KDE
sudo apt install xfce4-terminal  # XFCE

# Or set default manually
sudo update-alternatives --config x-terminal-emulator
```

**Issue: ADB Permission Denied**

**Solution:**
```bash
# Add udev rules
sudo wget -S -O /etc/udev/rules.d/51-android.rules https://raw.githubusercontent.com/M0Rf30/android-udev-rules/master/51-android.rules

sudo chmod a+r /etc/udev/rules.d/51-android.rules
sudo udevadm control --reload-rules

# Add user to plugdev group
sudo usermod -aG plugdev $USER

# Logout and login
```

---

## Error Messages

### "unauthorized"
- **Cause:** USB debugging not authorized
- **Fix:** Accept prompt on device, or revoke and re-authorize

### "device offline"
- **Cause:** ADB connection lost
- **Fix:** Reconnect device or restart ADB server

### "more than one device"
- **Cause:** Multiple devices connected without specifying which one
- **Fix:** Select specific device in app's device selector

### "protocol fault"
- **Cause:** ADB version mismatch or connection issue
- **Fix:** Update ADB, restart server, or use USB instead of wireless

### "encoder not found"
- **Cause:** Requested codec not available on device
- **Fix:** Try different codec or leave codec field empty

### "server version mismatch"
- **Cause:** Scrcpy server version doesn't match client
- **Fix:** Update scrcpy to latest version

---

## Diagnostic Tools

### Check System Configuration

**Verify All Components:**
```bash
# Check scrcpy
scrcpy --version

# Check ADB
adb --version

# Check devices
adb devices -l

# Check Flutter (if running from source)
flutter doctor
```

### Test Basic Functionality

**Minimal Command Test:**
```bash
# Simplest possible command
scrcpy

# With specific device
scrcpy -s <DEVICE_SERIAL>

# USB only
scrcpy --tcpip=disable
```

### Enable Verbose Logging

**Get Detailed Information:**
```bash
# In app: Advanced panel → Verbosity: verbose
# Or manually:
scrcpy -V verbose

# Full debug output
scrcpy -V debug
```

### Collect Diagnostic Information

**For Bug Reports:**
```
1. Operating System and version
2. scrcpy version (scrcpy --version)
3. ADB version (adb version)
4. Device model and Android version
5. Connection type (USB/Wireless)
6. Generated command from app
7. Full error message
8. Steps to reproduce
```

---

## Getting Further Help

### Before Asking for Help

1. ✅ Check this troubleshooting guide
2. ✅ Search existing GitHub issues
3. ✅ Try the command manually in terminal
4. ✅ Update scrcpy to latest version
5. ✅ Collect diagnostic information

### Where to Ask

- **GitHub Issues**: [Scrcpy GUI Issues](https://github.com/GeorgeEnglezos/Scrcpy-GUI/issues)
- **scrcpy Issues**: [Official scrcpy](https://github.com/Genymobile/scrcpy/issues)
- **GitHub Discussions**: Community help and questions
- **scrcpy Discord**: Real-time community support

### Creating a Good Bug Report

Include:
```markdown
**Environment:**
- OS: Windows 11 / macOS 13 / Ubuntu 22.04
- Scrcpy Version: 2.3.1
- App Version: 1.0.0
- Device: Samsung Galaxy S21, Android 13

**Issue:**
Clear description of the problem

**Steps to Reproduce:**
1. Step one
2. Step two
3. Step three

**Expected Behavior:**
What should happen

**Actual Behavior:**
What actually happens

**Generated Command:**
```
scrcpy --record output.mp4 --audio-codec opus
```

**Error Output:**
```
[paste full error message]
```

**Screenshots:**
[if applicable]
```

---

## Quick Reference

### Most Common Issues & Fixes

| Problem | Quick Fix |
|---------|-----------|
| Device not detected | `adb kill-server && adb start-server` |
| Wireless won't connect | Ensure USB connected first, same WiFi network |
| Audio not working | Update scrcpy to 2.0+, try different audio source |
| High latency | Use USB, reduce bitrate to 4M |
| scrcpy not found | Add to PATH or set path in Settings |
| Settings not saving | Check folder permissions |
| Encoder not found | Clear codec field, let scrcpy auto-select |
| Frame drops | Lower FPS, reduce resolution |

---

**Still having issues? See [USER_GUIDE.md](USER_GUIDE.md) for detailed usage instructions.**

**For feature information, see [FEATURES.md](FEATURES.md)**

**For bug reports, visit [GitHub Issues](https://github.com/GeorgeEnglezos/Scrcpy-GUI/issues)**
