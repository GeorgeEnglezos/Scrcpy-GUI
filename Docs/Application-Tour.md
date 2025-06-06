# A Tour of the Scrcpy-GUI!

Let's take a quick walk through the Scrcpy-GUI application to get you familiar with its features and layout.

# Home Tab

This is your main page, where you'll find all the options needed for interacting with your Android device.

### Scrcpy Settings

These sections allow you to fine-tune how Scrcpy interacts with your device.

```
1) Select a Device: Scrcpy-GUI lets you cast from multiple Android devices simultaneously. Just pick the device you want to cast from the dropdown menu. If your device is connected via both Wi-Fi and a USB cable, you'll see both connection options listed.
```

```
2) Package Selector: Use this to choose an application from your phone and open it with Scrcpy, either on the main display or within a virtual display. This option might be a lifesaver if your Virtual Display doesn't show you the application menu. It is suggested to use a Frontend in that case like Daijishou, Nova launcher etc.

3) General Section: Here you'll find the most useful generic Scrcpy options. In case you ever need a parameter that's missing in the GUI write it in the Extra Parameters Text field.

4) Audio Section: Access various audio-related settings for your cast.

5) Virtual Display Section: Configure options for opening a new virtual display on your Android device. Combine it with the Package Selector for the best experience.

6) Recording Section: Settings for recording your Scrcpy cast.
```

### Commands Preview and Output

```
7) ADB & Scrcpy Installation Panel: This panel confirms if Scrcpy and ADB are recognized by the application and whether a device is correctly connected.

8) Wireless Connection Panel: Easily connect to your device wirelessly using its IP address and TCP.
    > Start Manual Connection: Initiate a connection using the IP and port you've entered.
    > Auto Start Connection: Connect your phone wirelessly with a single click – no need to manually type your IP or preferred TCP port.
    > Close Connection: Stop the active wireless connection. (This might take a few seconds.)

9) Command Preview: See the Scrcpy command that's generated based on all your selected options.

10) Output Preview: View essential error messages from your Scrcpy commands. (To see the complete log, enable the related setting in the Settings Tab.)
```

# Commands Tab

Here you'll find all your saved commands. You can execute them with a simple click, or export them as executable .bat files for quick access.

# Resources Tab

This tab provides helpful information and links:

```
1) ADB & Scrcpy Installation Panel: This panel confirms if Scrcpy and ADB are recognized by the application and whether a device is correctly connected.

2) Links: Direct links to the official Scrcpy documentation and the Scrcpy-GUI project repository.

3) Useful Commands: Find handy commands for installing Scrcpy and ADB.
```

# Settings Tab

Adjust the application's behavior and user interface here:

```
1) Full Output Log: Enable this option to open a command prompt window whenever you run a Scrcpy command, allowing you to view the complete output log. It's the same with running scrcpy from cmd.
2) UI Settings: Customize the Main Page by hiding certain UI elements.
```
