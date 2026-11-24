# Troubleshooting

## The device does not appear

1. Turn on USB debugging: tap Settings → About Phone → Build Number 7 times, then enable Settings → Developer Options → USB Debugging.
2. Accept the "Allow USB debugging" prompt on the device.
3. Try another cable or port. Some cables only charge.
4. Run `adb devices` in a terminal to see whether ADB finds the device.
5. On Windows, install the manufacturer's USB driver or the [Google USB Driver](https://developer.android.com/studio/run/win-usb).

## scrcpy or ADB is not found

Scrcpy GUI runs `scrcpy` and `adb` from the folder set in Settings → Scrcpy Directory. Leave that field empty to use the copies on your PATH, which is usually right after a package-manager install. scrcpy's release zips include `adb`, so pointing Scrcpy Directory at the extracted folder covers both.

To check scrcpy outside the app, run `scrcpy --version`. If two ADB versions fight over the connection, restart the server with `adb kill-server`, then `adb start-server`.

## Wi-Fi connection fails

1. Put the device and the computer on the same network.
2. Connect over USB first, then click the Wi-Fi button.
3. Check that a firewall is not blocking port `5555`, ADB's default TCP port.
4. Try it by hand: `adb tcpip 5555`, then `adb connect <device-ip>:5555`.
5. On Android 11 or later you can pair with Wireless Debugging in Developer Options instead.

## The mirror window is black

Some apps block screen capture, banking and streaming apps among them. Make sure the device screen is on and unlocked. Lowering the video bitrate or resolution in the General panel can also help.

## No audio

Audio forwarding needs Android 11 or later. On Android 11 the screen must be unlocked when mirroring starts. If audio still fails, try another audio codec or source in the Audio panel.

## The app crashes on start

Delete the settings file to reset everything to defaults, then start the app again:

- Windows: `%APPDATA%\ScrcpyGui\scrcpy_gui_settings.json`
- macOS: `~/Library/Application Support/ScrcpyGui/scrcpy_gui_settings.json`
- Linux: `~/.config/ScrcpyGui/scrcpy_gui_settings.json`

## Recordings are missing

Check that Settings → Recordings Directory points to a folder you can write to and that the disk has space.

## The Scripts tab is missing

Turn on Settings → Show Scripts tab, and set Settings → Scripts Directory to the folder that holds your scripts (`.bat` and `.cmd` on Windows, `.sh` on Linux and macOS, `.command` on macOS).

## Mirroring lags or uses a lot of CPU

- Lower the resolution with Max Size, for example `1024`.
- Lower the video bitrate, for example `4M`.
- Pick a hardware encoder for the video codec in the General panel, if your device lists one.
- Use USB instead of Wi-Fi.

## Still stuck?

Open an issue on [GitHub](https://github.com/GeorgeEnglezos/Scrcpy-GUI/issues) with your OS and version, your scrcpy version (`scrcpy --version`) and the error message. For a log, turn on Settings → Enable logging and copy it from the Logs tab.
