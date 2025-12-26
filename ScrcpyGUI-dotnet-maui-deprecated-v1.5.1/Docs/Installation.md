# 🛠️ Installation Steps (for Windows)

## 🪟 Scrcpy & ADB ([Scrcpy docs](https://github.com/Genymobile/scrcpy/blob/master/doc/windows.md))

To use the Scrcpy-Gui application you'll need to install **ADB** (Android Debug Bridge) and **Scrcpy** on your Windows machine.

### Install via Winget (Recommended)

This is the easiest method as Winget will also download ADB for you.

```
winget install --exact Genymobile.scrcpy
```
### Install via Chocolatey
```
choco install scrcpy
choco install adb    # Run this if you don't have ADB yet
```
### Install via Scoop

```
scoop install scrcpy
scoop install adb    # Run this if you don't have ADB yet
```
### Verify Your Installation

Let's make sure Scrcpy and ADB were installed correctly. Open your command prompt or powershell and run these commands:

```
scrcpy --version
adb --version
```
If the commands return version numbers, you're all set! If you see messages like "scrcpy is not recognized" or "adb is not recognized," try rebooting your Windows device and running the commands again. Another way to confirm if ADB and Scrcpy are working properly is to check the relevant panel within the Scrcpy-Gui application itself.

<p align="center">
  <img src="https://github.com/user-attachments/assets/107d873e-0d28-4262-b4be-fa005504bd8e" width="50%" alt="image">
</p>

## 🤖 Android - Developer Settings & USB Debugging

To allow your Windows device to recognize your Android device for development purposes, you need to enable USB debugging. These settings are essential for advanced functionalities like using ADB (Android Debug Bridge) for various development tasks or mirroring your device's screen with tools like Scrcpy.

### Unlock Developer Settings

By default, the Developer options menu is hidden on Android devices. Here's how to make it visible:

1.  **Open Settings**: On your Android device, find and tap the `Settings` app.
2.  **Navigate to About Phone/Device**: Scroll down and look for `About phone`, `About device`, or a similar option. The exact name may vary slightly depending on your Android version and device manufacturer.
3.  **Find Build Number**: Within the "About phone" section, locate the `Build number`. You might need to scroll down to find it.
4.  **Tap Build Number Repeatedly**: Tap the `Build number` **seven times** in quick succession. You'll see a small pop-up message indicating your progress, like "You are now X steps away from being a developer."
5.  **Developer Options Unlocked**: After the seventh tap, you'll see a message that says "You are now a developer!" or "Developer options are now enabled."

### Enable USB Debugging

Once Developer options are unlocked, you can enable USB debugging:

1.  **Go back to the main Settings menu.**
2.  **Access Developer Options**: Scroll down, and you should now see a new option called `Developer options` (or `Developer options` within "System" or "System & updates" on some devices). Tap on it.
3.  **Enable USB Debugging**: Inside the Developer options menu, locate `USB debugging`. Tap the toggle switch next to `USB debugging` to enable it. A pop-up dialog will appear asking you to confirm whether you want to "Allow USB debugging." Tap `OK` or `Allow` to confirm.

### Verify Device Recognition

Now, let's connect your Android device to your PC and verify it's recognized:

1.  **Connect your phone with a USB cable.**
2.  **Authorize Debugging**: On your Android device, you may see a pop-up asking to `Allow USB debugging?` with your computer's RSA key fingerprint. **Check** the "Always allow from this computer" box if it's a trusted computer, then tap `Allow`.
<p align="center">
<img src="https://github.com/user-attachments/assets/f17e2eb2-6cb0-4db1-8284-cd24cbdcdb93" width="20%" alt="image">
</p>
On your computer, open a command prompt or terminal and run the following command:

```bash
adb devices
```

If your device is properly connected, you should see your device listed, usually with "device" next to its serial number. For example:

```bash
List of devices attached
XXXXXXXXXXXXXX	device
```

<p align="center">
  <img src="https://github.com/user-attachments/assets/e862a35c-d26a-4a4b-913b-60750b0881e8" width="50%" alt="Developer options enabled notification">
</p>

If it shows "unauthorized," ensure you have authorized the connection on your phone as described in step 2. If no device is listed, ensure your USB cable is working and try restarting the ADB server with adb `kill-server` and then `adb devices` again.

