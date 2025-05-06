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


    public static List<string> OutputHistory = new();  // Global list to track all outputs
    public static List<string> ErrorHistory = new();   // Global list to track all error outputs

    public static async Task<CmdCommandResponse> RunAdbCommandAsync(CommandEnum commandType, string? command)
    {
        var response = new CmdCommandResponse();

        try
        {
            // Set up the process information for cmd.exe
            ProcessStartInfo startInfo = new ProcessStartInfo
            {
                FileName = "cmd.exe",
                Arguments = $"/c \"{command}\"",  // Command to run
                WindowStyle = ProcessWindowStyle.Normal,
                UseShellExecute = false,
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                CreateNoWindow = true  // Hide the command window
            };

            // Store the last command if it's of the RunScrcpy type
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

            // Log the process exit code
            Debug.WriteLine($"Exit Code: {process.ExitCode}");

            // Capture the output and error from the StringBuilder objects
            var output = outputBuilder.ToString();
            var errorOutput = errorBuilder.ToString();

            // Store all outputs in the global lists for history tracking
            if (!string.IsNullOrEmpty(output))
            {
                OutputHistory.Add(output);  // Keep all outputs
            }

            if (!string.IsNullOrEmpty(errorOutput))
            {
                ErrorHistory.Add(errorOutput);  // Keep all error outputs
            }

            // Determine what to set as the response output
            response.RawOutput = output;
            response.RawError = errorOutput;
            response.Output = string.IsNullOrEmpty(errorOutput) ? output : errorOutput;

            response.ExitCode = process.ExitCode;

            return response;
        }
        catch (Exception ex)
        {
            // Catch any exceptions and log them
            Debug.WriteLine($"Exception: {ex.Message}");
            response.Output = $"Error: {ex.Message}";
            return response;
        }
    }

    public static async Task<bool> CheckIfAdbIsInstalled()
    {
        var result = await RunAdbCommandAsync(CommandEnum.RunScrcpy, "adb version");
        return result.RawOutput.Contains("Android Debug Bridge");
    }


    public async static Task<bool> CheckIfScrcpyIsInstalled()
    {
        try
        {
            // Run scrcpy with no arguments to check if it is installed and accessible.
            var result = await RunAdbCommandAsync(CommandEnum.RunScrcpy, "scrcpy --version");

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

    public static async Task<bool> CheckIfDeviceIsConnected()
    {
        var result = await RunAdbCommandAsync(CommandEnum.RunScrcpy, "adb devices");
        var lines = result.Output.Split(new[] { '\r', '\n' }, StringSplitOptions.RemoveEmptyEntries);

        // Skip the first line ("List of devices attached") and check if any subsequent line contains "device"
        return lines.Skip(1).Any(line => line.Contains("\tdevice"));
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