using Microsoft.Maui.Controls;
using Microsoft.Maui.Controls.Internals;
using Microsoft.VisualBasic;
using ScrcpyGUI.Models;
using System;
using System.Collections.Generic;
using System.Data;
using System.Diagnostics;
using System.Linq;
using System.Net;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading.Tasks;

/// <summary>
/// Static service class for executing ADB (Android Debug Bridge) and Scrcpy commands.
/// DEPRECATED: This .NET MAUI application is being replaced by a Flutter version.
/// Manages device connections, command execution, and codec/encoder detection.
/// </summary>
public static class AdbCmdService
{
    /// <summary>
    /// ADB command to list all installed packages on the device.
    /// </summary>
    public const string allPackagesCommand = "shell pm list packages";

    /// <summary>
    /// ADB command to list only user-installed packages (excludes system apps).
    /// </summary>
    public const string installedPackagesCommand = "shell pm list packages -3";

    /// <summary>
    /// Gets or sets the list of currently connected Android devices.
    /// </summary>
    public static List<ConnectedDevice> connectedDeviceList = new List<ConnectedDevice>();

    /// <summary>
    /// Gets or sets the currently selected device for command execution.
    /// </summary>
    public static ConnectedDevice selectedDevice = new ConnectedDevice();

    /// <summary>
    /// Gets or sets the file system path to the Scrcpy executable directory.
    /// </summary>
    public static string scrcpyPath = "";

    /// <summary>
    /// Gets or sets the file system path where screen recordings are saved.
    /// </summary>
    public static string recordingsPath = "";

    /// <summary>
    /// Enumeration of command types for command execution routing.
    /// </summary>
    public enum CommandEnum
    {
        /// <summary>Get list of packages from device.</summary>
        GetPackages,
        /// <summary>Execute Scrcpy screen mirroring.</summary>
        RunScrcpy,
        /// <summary>Check ADB version.</summary>
        CheckAdbVersion,
        /// <summary>Check Scrcpy version.</summary>
        CheckScrcpyVersion,
        /// <summary>Check for connected devices.</summary>
        CheckConnectedDevices,
        /// <summary>TCP/IP connection command.</summary>
        Tcp,
        /// <summary>Get device IP address.</summary>
        PhoneIp
    }

    /// <summary>
    /// Enumeration of device connection types.
    /// </summary>
    public enum ConnectionType
    {
        /// <summary>No connection.</summary>
        None,
        /// <summary>USB connection.</summary>
        Usb,
        /// <summary>Wireless TCP/IP connection.</summary>
        TcpIp
    }


    /// <summary>
    /// Executes a Scrcpy command on the selected device.
    /// Automatically prepends device selection and handles output/error redirection.
    /// </summary>
    /// <param name="command">The Scrcpy command string to execute.</param>
    /// <returns>Command response containing output, errors, and exit code.</returns>
    public static async Task<CmdCommandResponse> RunScrcpyCommand(string command)
    {
        var response = new CmdCommandResponse();
        bool showCmds = DataStorage.LoadData().AppSettings.OpenCmds;
        if (string.IsNullOrEmpty(selectedDevice.DeviceId))
        {
            // No device connected
            response.RawError = "No ADB device connected. \nMake sure USB debugging is enabled and try again!";
            return response;
        }

        command = command.Replace("scrcpy.exe", "");
        command = $"scrcpy.exe -s {selectedDevice.DeviceId} {command} ";

        // Command runs here
        ProcessStartInfo startInfo = new ProcessStartInfo
        {
            FileName = "cmd.exe",
            Arguments = $"/c \"{command}\"",
            WorkingDirectory = scrcpyPath,
            WindowStyle = showCmds ? ProcessWindowStyle.Normal : ProcessWindowStyle.Hidden,
            UseShellExecute = false,
            RedirectStandardOutput = !showCmds,
            RedirectStandardError = !showCmds,
            CreateNoWindow = !showCmds
        };

        Preferences.Set("lastCommand", command);

        // Prepare to capture output and error streams asynchronously
        var outputBuilder = new StringBuilder();
        var errorBuilder = new StringBuilder();

        // Process event handlers for async reading output and error streams
        Process process = new Process { StartInfo = startInfo };

        // Only attach handlers if redirection is enabled
        if (!showCmds)
        {
            process.OutputDataReceived += (sender, e) =>
            {
                if (!string.IsNullOrEmpty(e.Data))
                {
                    outputBuilder.AppendLine(e.Data);
                }
            };

            process.ErrorDataReceived += (sender, e) =>
            {
                if (!string.IsNullOrEmpty(e.Data))
                {
                    errorBuilder.AppendLine(e.Data);
                }
            };
        }

        await Task.Run(() =>
        {
            process.Start();
            Debug.WriteLine($"Process started with ID: {process.Id}");

            // ONLY call BeginOutputReadLine and BeginErrorReadLine if streams are redirected
            if (!showCmds)
            {
                process.BeginOutputReadLine();
                process.BeginErrorReadLine();
            }

            // Wait for the process to exit
            process.WaitForExit();
        });

        // Capture the output and error from the StringBuilder objects
        // Only if streams were redirected
        if (!showCmds)
        {
            var output = outputBuilder.ToString();
            var errorOutput = errorBuilder.ToString();
            response.RawOutput = output;
            response.RawError = errorOutput;
            response.Output = string.IsNullOrEmpty(errorOutput) ? output : errorOutput;
        }
        else
        {
            // If CMD window was shown, there's no captured output/error via redirection
            response.RawOutput = "Command run in a separate CMD window. Output not captured.";
            response.Output = response.RawOutput;
        }

        response.ExitCode = process.ExitCode;

        return response;
    }

    /// <summary>
    /// Executes an ADB command asynchronously with automatic device selection.
    /// Handles device-specific routing and wireless device detection.
    /// </summary>
    /// <param name="commandType">The type of command being executed.</param>
    /// <param name="command">The ADB command string to execute.</param>
    /// <returns>Command response containing output, errors, and exit code.</returns>
    public static async Task<CmdCommandResponse> RunAdbCommandAsync(CommandEnum commandType, string? command)
    {
        var response = new CmdCommandResponse();

        try
        {
            if (commandType == CommandEnum.GetPackages || commandType == CommandEnum.Tcp || commandType == CommandEnum.PhoneIp)
            {
                var deviceToUseForCommand = selectedDevice.DeviceId;
                if (command.Equals("usb") || command.Equals("disconnect"))
                {
                    deviceToUseForCommand = FindWirelessDeviceInList();
                    if (string.IsNullOrEmpty(deviceToUseForCommand))
                    {
                        response.RawError = "No Wireless device found!";
                        return response;
                    }
                }
                command = $"adb -s {deviceToUseForCommand} {command} ";
            }

            // Command runs here
            ProcessStartInfo startInfo = new ProcessStartInfo
            {
                FileName = "cmd.exe",
                Arguments = $"/c \"{command}\"",
                WorkingDirectory = scrcpyPath,
                WindowStyle = ProcessWindowStyle.Hidden,
                UseShellExecute = false,
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                CreateNoWindow = true
            };

            // Prepare to capture output and error streams asynchronously
            var outputBuilder = new StringBuilder();
            var errorBuilder = new StringBuilder();

            // Process event handlers for async reading output and error streams
            Process process = new Process { StartInfo = startInfo };

            // Fixed: Added event handlers for output capture
            process.OutputDataReceived += (sender, e) =>
            {
                if (!string.IsNullOrEmpty(e.Data))
                {
                    outputBuilder.AppendLine(e.Data);
                }
            };

            process.ErrorDataReceived += (sender, e) =>
            {
                if (!string.IsNullOrEmpty(e.Data))
                {
                    errorBuilder.AppendLine(e.Data);
                }
            };

            // Run the process in the background (non-blocking)
            await Task.Run(() =>
            {
                process.Start();
                Debug.WriteLine($"Process started with ID: {process.Id}");

                process.BeginOutputReadLine();
                process.BeginErrorReadLine();

                // Wait for the process to exit
                process.WaitForExit();
            });

            // Capture the output and error from the StringBuilder objects
            var output = outputBuilder.ToString();
            var errorOutput = errorBuilder.ToString();
            response.RawOutput = output;
            response.RawError = errorOutput;
            response.Output = string.IsNullOrEmpty(errorOutput) ? output : errorOutput;

            response.ExitCode = process.ExitCode;

            return response;
        }
        catch (Exception ex)
        {
            Debug.WriteLine($"Exception: {ex.Message}");
            response.Output = $"Error: {ex.Message}";
            response.RawError = ex.ToString();
            return response;
        }
    }


    /// <summary>
    /// Checks if ADB (Android Debug Bridge) is installed and accessible.
    /// </summary>
    /// <returns>True if ADB is installed; otherwise, false.</returns>
    public static async Task<bool> CheckIfAdbIsInstalled()
    {
        var result = await RunAdbCommandAsync(CommandEnum.CheckAdbVersion, "adb version");
        return result.RawOutput.Contains("Android Debug Bridge");
    }

    /// <summary>
    /// Checks if Scrcpy is installed and accessible.
    /// </summary>
    /// <returns>True if Scrcpy is installed; otherwise, false.</returns>
    public async static Task<bool> CheckIfScrcpyIsInstalled()
    {
        try
        {
            var result = await RunAdbCommandAsync(CommandEnum.CheckScrcpyVersion, "scrcpy --version");

            // If the exit code is zero, scrcpy is installed and accessible.
            return result.ExitCode == 0;
        }
        catch (Exception ex)
        {
            // Log the exception for debugging if needed.
            Debug.WriteLine($"Error checking scrcpy installation: {ex.Message}");
            return false;
        }
    }

    /// <summary>
    /// Determines the type of connection for currently connected devices.
    /// Analyzes device identifiers to distinguish between USB and TCP/IP connections.
    /// </summary>
    /// <returns>The detected connection type (None, USB, or TCP/IP).</returns>
    public static async Task<ConnectionType> CheckDeviceConnection()
    {
        var result = await RunAdbCommandAsync(CommandEnum.CheckAdbVersion, "adb devices");
        var lines = result.Output.Split(new[] { '\r', '\n' }, StringSplitOptions.RemoveEmptyEntries);

        // Skip the header line
        foreach (var line in lines.Skip(1))
        {
            if (line.Contains("\tdevice"))
            {
                var parts = line.Split('\t');
                if (parts.Length > 0)
                {
                    var deviceIdentifier = parts[0].Trim();

                    // Check if it contains a colon, indicating IP:port
                    if (deviceIdentifier.Contains(':'))
                    {
                        var ipAddressPart = deviceIdentifier.Split(':')[0];
                        if (System.Net.IPAddress.TryParse(ipAddressPart, out _))
                        {
                            return ConnectionType.TcpIp;
                        }
                    }
                    // If no colon, try parsing the whole identifier as an IP
                    else if (System.Net.IPAddress.TryParse(deviceIdentifier, out _))
                    {
                        return ConnectionType.TcpIp; // Could be an older format or a direct IP
                    }
                    else if (!string.IsNullOrEmpty(deviceIdentifier))
                    {
                        return ConnectionType.Usb;
                    }
                }
            }
        }

        return ConnectionType.None; // No connected device found
    }

    /// <summary>
    /// Enables TCP/IP mode on the connected device at the specified port.
    /// </summary>
    /// <param name="port">The port number to use for TCP/IP connection (typically 5555).</param>
    /// <returns>Command output string.</returns>
    public async static Task<string> RunTCPPort(string port)
    {
        var result = await RunAdbCommandAsync(CommandEnum.Tcp, $"tcpip {port}");
        return result.Output.ToString();
    }

    /// <summary>
    /// Connects to a device wirelessly using TCP/IP.
    /// Masks IP addresses in the output for privacy.
    /// </summary>
    /// <param name="ip">The device IP address.</param>
    /// <param name="port">The port number (typically 5555).</param>
    /// <returns>Command output with masked IP addresses.</returns>
    public async static Task<string> RunPhoneIp(string ip, string port)
    {
        var result = await RunAdbCommandAsync(CommandEnum.Tcp, $"connect {ip}:{port}");

        // Mask all IPv4 addresses in the output
        string maskedOutput = Regex.Replace(
            result.Output.ToString(),
            @"\b(?:\d{1,3}\.){3}\d{1,3}\b",
            "***.***.***.***"
        );

        return maskedOutput;
    }
    
    /// <summary>
    /// Retrieves a list of all connected Android devices with their details.
    /// Queries each device for supported codec/encoder pairs.
    /// </summary>
    /// <returns>List of ConnectedDevice objects with codec/encoder information.</returns>
    public static List<ConnectedDevice> GetAdbDevices()
    {
        var list = new List<ConnectedDevice>();

        // Command runs here
        try
        {
            var process = new Process
            {
                StartInfo = new ProcessStartInfo
                {
                    FileName = Path.Combine(scrcpyPath, "adb"),
                    Arguments = "devices -l",
                    //WorkingDirectory = scrcpyPath,
                    RedirectStandardOutput = true,
                    UseShellExecute = false,
                    CreateNoWindow = true
                }
            };

            process.Start();

            while (!process.StandardOutput.EndOfStream)
            {
                var line = process.StandardOutput.ReadLine();

                if (string.IsNullOrWhiteSpace(line) || line.StartsWith("List"))
                    continue;

                var parts = line.Split(' ', StringSplitOptions.RemoveEmptyEntries);
                if (parts.Length < 2)
                    continue;

                var id = parts[0];
                var status = parts[1];

                // Skip offline or unauthorized devices
                if (status != "device")
                    continue;

                var modelEntry = parts.FirstOrDefault(p => p.StartsWith("model:"));
                var model = modelEntry != null ? modelEntry.Split(':')[1] : "Unknown";

                string displayId = IsIpAddress(id) ? "Wireless" : id;
                list.Add(new ConnectedDevice($"{model} - {displayId}", model, id));
            }
        }
        catch (Exception ex)
        {
            Debug.WriteLine($"Error loading devices: {ex.Message}");
        }

        if (connectedDeviceList.Count == 0) selectedDevice = new ConnectedDevice();
        connectedDeviceList = GetCodecsEncodersForEachDevice(list);
        return connectedDeviceList;
    }
    /// <summary>
    /// Queries each device for its supported audio and video codec/encoder pairs.
    /// Parses Scrcpy's --list-encoders output to populate device capabilities.
    /// </summary>
    /// <param name="devices">List of devices to query.</param>
    /// <returns>The same list with codec/encoder information populated.</returns>
    private static List<ConnectedDevice> GetCodecsEncodersForEachDevice(List<ConnectedDevice> devices)
    {
        foreach (var device in devices)
        {
            device.VideoCodecEncoderPairs = new List<string>();
            device.AudioCodecEncoderPairs = new List<string>();

            try
            {
                // Command runs here
                var process = new Process
                {
                    StartInfo = new ProcessStartInfo
                    {
                        FileName = Path.Combine(scrcpyPath, "scrcpy"),                        
                        WorkingDirectory = scrcpyPath,
                        Arguments = $"--list-encoders --serial {device.DeviceId}",
                        RedirectStandardOutput = true,
                        UseShellExecute = false,
                        CreateNoWindow = true
                    }
                };

                process.Start();

                bool parsingVideoEncoders = false;
                bool parsingAudioEncoders = false;

                while (!process.StandardOutput.EndOfStream)
                {
                    var line = process.StandardOutput.ReadLine();

                    if (string.IsNullOrWhiteSpace(line))
                        continue;

                    string codec = null;
                    string encoder = null;

                    var pattern = @"(--(?:audio|video)-encoder=[^\s]+)";
                    var match = Regex.Matches(line, pattern);

                    if (match.Count > 0)
                    {
                        // Get last match and trim after its value
                        var lastMatch = match[match.Count - 1];
                        line = line.Substring(0, lastMatch.Index + lastMatch.Length).Trim();
                    }

                    if (line.Contains("--video-codec") || line.Contains("--video-encoder")) {
                        device.VideoCodecEncoderPairs.Add(line);
                    }
                    if (line.Contains("--audio-codec") || line.Contains("--audio-encoder"))
                    {
                        device.AudioCodecEncoderPairs.Add(line);
                    }
                }
                process.WaitForExit();
            }
            catch (Exception ex)
            {
                Debug.WriteLine($"Error getting codecs/encoders for device {device.DeviceId}: {ex.Message}");
            }
        }

        return devices;
    }


    /// <summary>
    /// Determines if a string is a valid IPv4 address using regex pattern matching.
    /// </summary>
    /// <param name="input">The string to check.</param>
    /// <returns>True if the input is a valid IPv4 address; otherwise, false.</returns>
    public static bool IsIpAddress(string input)
    {
        return Regex.IsMatch(input, @"\b(?:\d{1,3}\.){3}\d{1,3}\b");
    }

    /// <summary>
    /// Retrieves the device's WiFi IP address from the wlan0 interface.
    /// </summary>
    /// <returns>The device's IP address, or empty string if not found.</returns>
    public static async Task<string> GetPhoneIp()
    {
        // This assumes you're using a shell command like: adb shell ip -f inet addr show wlan0
        var output = await RunAdbCommandAsync(CommandEnum.PhoneIp, "shell ip -f inet addr show wlan0");

        // Parse the IP address from output (only get the actual IP)
        var match = Regex.Match(output.Output, @"inet\s+(\d+\.\d+\.\d+\.\d+)");
        return match.Success ? match.Groups[1].Value : string.Empty;
    }

    /// <summary>
    /// Searches for a wirelessly connected device in the device list.
    /// Prioritizes the currently selected device if it's wireless.
    /// </summary>
    /// <returns>Device ID of a wireless device, or null if none found.</returns>
    private static string FindWirelessDeviceInList()
    {
        // If the currently selected device is already wireless, return its ID directly.
        if (IsIpAddress(selectedDevice.DeviceId))
        {
            return selectedDevice.DeviceId;
        }

        // If not, search the list of connected devices for the first wireless one.
        foreach (var device in connectedDeviceList)
        {
            if (IsIpAddress(device.DeviceId))
            {
                return device.DeviceId;
            }
        }

        return null;
    }

    /// <summary>
    /// Sets the Scrcpy executable path from saved application settings.
    /// Validates and creates the path if necessary.
    /// </summary>
    public static void SetScrcpyPath()
    {
        if (string.IsNullOrEmpty(DataStorage.staticSavedData.AppSettings.ScrcpyPath))
            scrcpyPath = "";
        else
        {
            scrcpyPath = DataStorage.staticSavedData.AppSettings.ScrcpyPath;
            DataStorage.ValidateAndCreatePath(scrcpyPath);
        }
    }
}