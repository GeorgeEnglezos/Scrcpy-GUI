# Troubleshooting

## Device Not Detected

**Symptom**: No device appears in the device dropdown after connecting via USB.

1. Ensure USB Debugging is enabled on the device:
   - Settings → About Phone → tap Build Number 7 times
   - Settings → Developer Options → enable USB Debugging
2. Accept the "Allow USB Debugging" prompt on your device screen
3. Try a different USB cable or port (some cables are charge-only)
4. Run `adb devices` in a terminal to verify ADB sees the device
5. On Windows, install the manufacturer's USB driver or [Google USB Driver](https://developer.android.com/studio/run/win-usb)

---

## scrcpy Not Found / Path Error

**Symptom**: Error about scrcpy not being found when clicking Run.

- Go to **Settings** and set the **scrcpy directory** to the folder containing the `scrcpy` executable
- Verify scrcpy works independently: open a terminal and run `scrcpy --version`
- If installed via package manager, the directory may already be on PATH — leave the setting blank to use PATH

---

## ADB Not Found

**Symptom**: Devices never appear; logs show ADB errors.

- scrcpy bundles `adb` — ensure the scrcpy directory is set correctly in Settings
- If using a system-installed ADB, ensure it's on PATH
- On Windows, check that no other ADB version conflict exists (`adb kill-server && adb start-server`)

---

## Wireless Connection Fails

**Symptom**: "Connect Wirelessly" button fails or device disconnects immediately.

1. Ensure device and computer are on the same WiFi network
2. Complete the initial USB connection step before switching to wireless
3. Check if a firewall is blocking port `5555` (default ADB TCP port)
4. Try manually: `adb tcpip 5555` then `adb connect <device-ip>:5555`
5. On Android 11+, use the Wireless Debugging option in Developer Options instead

---

## Black Screen / No Video

**Symptom**: scrcpy window opens but shows a black screen.

- Some apps block screen capture (banking apps, Netflix, etc.) — this is a device restriction
- Try disabling **Secure Flag** in Advanced settings if the target app allows it
- Check if the device screen is on and unlocked
- Try lowering the video bitrate or resolution in Common Commands panel

---

## Audio Not Working

**Symptom**: No audio is forwarded from the device.

- Audio forwarding requires Android 11 or higher
- Ensure no audio is playing through the device speaker (some devices block capture when nothing is playing)
- Check the Audio Commands panel — try switching the audio codec or source
- Run with `--no-audio` flag first to confirm the issue is audio-specific

---

## App Crashes on Launch

**Symptom**: Scrcpy GUI closes immediately or shows an error on startup.

- Check the logs file if file logging is enabled (Settings → Enable File Logging)
- Delete the settings file and restart to reset to defaults:
  - Windows: `%APPDATA%\scrcpy_gui\settings.json`
  - macOS: `~/Library/Application Support/scrcpy_gui/settings.json`
  - Linux: `~/.config/scrcpy_gui/settings.json`

---

## Recordings Not Saving

**Symptom**: Recording completes but no file is found.

- Set the **Recordings directory** in Settings to a valid writable path
- Ensure sufficient disk space is available
- Check the filename — if a file with the same name already exists it may be overwritten silently

---

## Scripts/BAT Files Tab Not Visible

**Symptom**: The Scripts tab is missing from the sidebar.

- Go to **Settings** → enable **Show Scripts Tab**
- Set the **Scripts directory** to the folder where your `.bat` / `.sh` / `.command` files are stored

---

## High CPU / Lag

**Symptom**: scrcpy or the host machine runs slowly during mirroring.

- Lower the video resolution: `--max-size 1024`
- Lower the bitrate: `--video-bit-rate 4M`
- Switch to a hardware encoder in the Audio/Video panels if available for your device
- Use a wired USB connection instead of wireless for lower latency

---

## Still Stuck?

Open an issue at [GitHub Issues](https://github.com/GeorgeEnglezos/Scrcpy-GUI/issues) and include:
- Your OS and version
- scrcpy version (`scrcpy --version`)
- The error message or log output (Settings → Enable Logging → copy from Logs tab)
