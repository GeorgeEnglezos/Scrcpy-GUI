using ScrcpyGUI.Models;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

public static class AdbCmdService
{
    const string fullCommand = "scrcpy.exe --pause-on-exit=if-error --new-display=3840x2160";
    public const string installedPackagesCommand = "adb shell pm list packages -3";
    //public const string scrcpyPathTemp = "C:\\scrcpy-win64-v3.1";

    public enum CommandEnum
    {
        GetPackages,
        RunScrcpy,
        CheckAdbVersion,
        CheckScrcpyVersion,
        CheckConnectedDevices
    }


    public static CmdCommandResponse RunAdbCommand(string? scrcpyPath, CommandEnum commandType, string? command)
    {
        var response = new CmdCommandResponse();

        try
        {
            Process process = new Process();
            ProcessStartInfo startInfo = new ProcessStartInfo();
            startInfo.WindowStyle = ProcessWindowStyle.Normal;
            startInfo.FileName = "cmd.exe";

            // Specify the path to the folder containing adb.exe
            //string adbFilePath = Path.Combine(string.IsNullOrEmpty(scrcpyPath) ? "" : scrcpyPathTemp, command);  // Full path to scrcpy.exe
            if(commandType == CommandEnum.RunScrcpy) Preferences.Set("lastCommand", command);

            //startInfo.WorkingDirectory = string.IsNullOrEmpty(scrcpyPath) ? scrcpyPathTemp : scrcpyPathTemp; // Set the working directory
            //startInfo.Arguments = $"/c \"{adbFilePath}\""; // Use full path in arguments
            startInfo.Arguments = $"/c \"{command}\""; // Use full path in arguments
            startInfo.UseShellExecute = false;
            startInfo.RedirectStandardOutput = true;
            startInfo.RedirectStandardError = true;
            startInfo.CreateNoWindow = true;

            process.StartInfo = startInfo;
            process.Start();

            Debug.WriteLine($"Process started with ID: {process.Id}");

            string output = process.StandardOutput.ReadToEnd();
            string errorOutput = process.StandardError.ReadToEnd();
            process.WaitForExit();

            Debug.WriteLine($"Exit Code: {process.ExitCode}");

            if (!string.IsNullOrEmpty(errorOutput))
            {
                Debug.WriteLine($"Error Output: {errorOutput}");
                response.Output = errorOutput;
                return response;

            }
            //Debug.WriteLine($"Standard Output: {output}");
            response.Output = output;
            return response;
        }
        catch (Exception ex)
        {
            Debug.WriteLine($"Exception: {ex.Message}");
            response.Output = $"Error: {ex.Message}";
            return response;
        }
    }

    public static async Task<CmdCommandResponse> RunAdbCommandAsync(string? scrcpyPath, CommandEnum commandType, string? command)
    {
        var response = new CmdCommandResponse();

        try
        {
            Process process = new Process();
            ProcessStartInfo startInfo = new ProcessStartInfo
            {
                WindowStyle = ProcessWindowStyle.Normal,
                FileName = "cmd.exe",
                Arguments = $"/c \"{command}\"",
                UseShellExecute = false,
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                CreateNoWindow = true
            };

            if (commandType == CommandEnum.RunScrcpy)
                Preferences.Set("lastCommand", command);

            process.StartInfo = startInfo;

            var outputBuilder = new StringBuilder();
            var errorBuilder = new StringBuilder();

            process.OutputDataReceived += (sender, e) =>
            {
                if (!string.IsNullOrEmpty(e.Data))
                    outputBuilder.AppendLine(e.Data);
            };

            process.ErrorDataReceived += (sender, e) =>
            {
                if (!string.IsNullOrEmpty(e.Data))
                    errorBuilder.AppendLine(e.Data);
            };

            await Task.Run(() =>
            {
                process.Start();
                Debug.WriteLine($"Process started with ID: {process.Id}");

                process.BeginOutputReadLine();
                process.BeginErrorReadLine();

                process.WaitForExit();
            });

            Debug.WriteLine($"Exit Code: {process.ExitCode}");

            var output = outputBuilder.ToString();
            var errorOutput = errorBuilder.ToString();

            if (!string.IsNullOrEmpty(errorOutput))
            {
                Debug.WriteLine($"Error Output: {errorOutput}");
                response.Output = errorOutput;
                return response;
            }

            response.Output = output;
            return response;
        }
        catch (Exception ex)
        {
            Debug.WriteLine($"Exception: {ex.Message}");
            response.Output = $"Error: {ex.Message}";
            return response;
        }
    }




    public static bool CheckIfAdbIsInstalled()
    {
        var result = RunAdbCommand(null, CommandEnum.RunScrcpy, "adb version");
        return result.Output.Contains("Android Debug Bridge");
    }

    public static bool CheckIfScrcpyIsInstalled()
    {
        var result = RunAdbCommand(null, CommandEnum.RunScrcpy, "scrcpy --version");
        return result.Output.Contains("scrcpy");
    }

    public static bool CheckIfDeviceIsConnected()
    {
        var result = RunAdbCommand(null, CommandEnum.RunScrcpy, "adb devices");
        var lines = result.Output.Split(new[] { '\r', '\n' }, StringSplitOptions.RemoveEmptyEntries);

        // Skip the first line ("List of devices attached") and check if any subsequent line contains "device"
        return lines.Skip(1).Any(line => line.Contains("\tdevice"));
    }
}