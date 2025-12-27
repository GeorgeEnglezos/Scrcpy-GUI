# Troubleshooting

Quick fixes for common issues.

## Device Not Detected

**Quick fix:**
```bash
adb kill-server
adb start-server
adb devices
```

**Check USB debugging:**
- Settings → Developer Options → USB Debugging
- Accept "Allow USB debugging" prompt on device
- Try a different USB cable (some are charge-only)

**Windows only:** Update device drivers in Device Manager

## Wireless Connection Fails

1. Connect via USB first (required for initial setup)
2. Ensure both devices are on same WiFi network
3. Check firewall allows port 5555
4. Manual setup:
   ```bash
   adb tcpip 5555
   adb connect <DEVICE_IP>:5555
   ```

## Scrcpy Won't Start

**Verify scrcpy is installed:**
```bash
scrcpy --version
```

**If not found, add to PATH or install:**
- Windows: `scoop install scrcpy`
- macOS: `brew install scrcpy`
- Linux: `sudo apt install scrcpy`

## Audio Not Working

- Requires scrcpy 2.0+
- Try different audio source in Audio panel
- Increase audio buffer to 512 or 1024

## Performance Issues

**For high latency:**
- Use USB instead of wireless
- Lower video bitrate to 4M
- Reduce max size to 1280
- Disable audio if not needed

**For frame drops:**
- Limit FPS to 30
- Try H.264 codec
- Close background apps

## Common Error Messages

| Error | Fix |
|-------|-----|
| "unauthorized" | Accept USB debugging prompt on device |
| "device offline" | Run `adb reconnect` or restart device |
| "encoder not found" | Clear codec field, let scrcpy auto-select |
| "more than one device" | Select specific device in app |

## Still Having Issues?

1. Test manually: Copy command from app and run in terminal to see full error
2. Enable verbose logging: Advanced panel → Verbosity: verbose
3. Report issues: [GitHub Issues](https://github.com/GeorgeEnglezos/Scrcpy-GUI/issues)
