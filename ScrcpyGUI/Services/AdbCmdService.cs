using Microsoft.Maui.Controls.Internals;
using ScrcpyGUI.Models;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

public static class AdbCmdService
{
    public const string allPackagesCommand = "adb shell pm list packages";
    public const string installedPackagesCommand = "adb shell pm list packages -3";

    public enum CommandEnum
    {
        GetPackages,
        RunScrcpy,
        CheckAdbVersion,
        CheckScrcpyVersion,
        CheckConnectedDevices,
        Tcp,
        PhoneIp
    }

    public enum ConnectionType
    {
        None,
        Usb,
        TcpIp
    }

    public static List<string> OutputHistory = new();  // Global list to track all outputs
    public static List<string> ErrorHistory = new();   // Global list to track all error outputs

    public static async Task<CmdCommandResponse> RunAdbCommandAsync(CommandEnum commandType, string? command)
    {
        var response = new CmdCommandResponse();

        bool showCmds = DataStorage.LoadData().AppSettings.OpenCmds && commandType == CommandEnum.RunScrcpy;

        try
        {
            ProcessStartInfo startInfo = new ProcessStartInfo
            {
                FileName = "cmd.exe",
                Arguments = $"/c \"{command}\"",
                WindowStyle = ProcessWindowStyle.Normal,
                UseShellExecute = false,
                RedirectStandardOutput = !showCmds,
                RedirectStandardError = !showCmds,
                CreateNoWindow = !showCmds // Hide the command window
            };

            if (commandType == CommandEnum.RunScrcpy)
            {
                Preferences.Set("lastCommand", command);
            }

            // Prepare to capture output and error streams asynchronously
            var outputBuilder = new StringBuilder();
            var errorBuilder = new StringBuilder();

            // Process event handlers for async reading output and error streams
            Process process = new Process { StartInfo = startInfo };

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

                // Begin asynchronous read of the output and error streams
                process.BeginOutputReadLine();
                process.BeginErrorReadLine();

                // Wait for the process to exit
                process.WaitForExit();
            });

            // Capture the output and error from the StringBuilder objects
            var output = outputBuilder.ToString();
            var errorOutput = errorBuilder.ToString();

            // Store all outputs in the global lists for history tracking
            if (!string.IsNullOrEmpty(output))
            {
                OutputHistory.Add(output);
            }

            if (!string.IsNullOrEmpty(errorOutput))
            {
                ErrorHistory.Add(errorOutput);
            }

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
            return response;
        }
    }

    public static async Task<bool> CheckIfAdbIsInstalled()
    {
        var result = await RunAdbCommandAsync(CommandEnum.CheckAdbVersion, "adb version");
        return result.RawOutput.Contains("Android Debug Bridge");
    }


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

    public async static Task<string> RunTCPPort(string port)
    {
        var result = await RunAdbCommandAsync(CommandEnum.Tcp, $"adb tcpip {port}");
        return result.Output.ToString();
    }

    public async static Task<string> RunPhoneIp(string ip)
    {
        var result = await RunAdbCommandAsync(CommandEnum.Tcp, $"adb connect {ip}");
        return result.Output.ToString();
    }
}