using System.ComponentModel;
using System.Data;
using System.Diagnostics;
using System.Runtime.CompilerServices;
using ScrcpyGUI.Models;

namespace ScrcpyGUI.Controls
{
    public partial class WirelessConnectionPanel : ContentView
    {
        public WirelessConnectionPanel()
        {
            InitializeComponent();
        }

        private async void OnResetToUsb(object sender, EventArgs e)
        {
            var tcpResponse = await AdbCmdService.RunAdbCommandAsync(AdbCmdService.CommandEnum.Tcp, "usb");
            if (!string.IsNullOrEmpty(tcpResponse.RawError)) { 
                await ShowDialog("Error", $"{tcpResponse.RawError}");
                return;
            }

            var ipResponse = await AdbCmdService.RunAdbCommandAsync(AdbCmdService.CommandEnum.Tcp, "disconnect");
            if (!string.IsNullOrEmpty(ipResponse.RawError)) {
                await ShowDialog("Error", $"{ipResponse.RawError}");
                return;
            }

            if (ipResponse.Output.ToString().Contains("disconnected")) ipResponse.Output = "Disconnected wireless device";
            await ShowDialog($"Stop Connection", $"{tcpResponse.Output}\n{ipResponse.Output}");
        }

        private async void OnAutoStartConnection(object sender, EventArgs e)
        {
            var port = TcpipEntry.Text?.Trim();
            if (string.IsNullOrWhiteSpace(port))
                port = "5555";

            var ip = await AdbCmdService.GetPhoneIp();
            if (string.IsNullOrEmpty(ip))
            {
                await ShowDialog("Connection Failed", "Could not automatically retrieve phone IP. Make sure the device is connected via USB.");
                return;
            }

            var portResult = await AdbCmdService.RunTCPPort(port);
            var ipResult = await AdbCmdService.RunPhoneIp(ip);

            string summary = $"\nTCP Result:\n{portResult}\n\nIP Result:\n{ipResult}";
            await ShowDialog("Auto Connection Status", summary);
        }

        private async void OnStartConnection(object sender, EventArgs e)
        {
            var port = TcpipEntry.Text?.Trim();
            var ip = PhoneIpEntry.Text?.Trim();

            if (string.IsNullOrEmpty(port) && string.IsNullOrEmpty(ip))
            {
                await ShowDialog("Missing Input", "Please enter both the port and IP address.");
                return;
            }

            if (string.IsNullOrEmpty(port))
            {
                await ShowDialog("Missing Port", "Please enter a valid TCP port.");
                return;
            }

            if (string.IsNullOrEmpty(ip))
            {
                await ShowDialog("Missing IP", "Please enter a valid IP address.");
                return;
            }

            var portResult = await AdbCmdService.RunTCPPort(port);
            var ipResult = await AdbCmdService.RunPhoneIp(ip);

            string summary = $"TCP Result:\n{portResult}\n\nIP Result:\n{ipResult}";
            await ShowDialog("Connection Status", summary);
        }

        private async Task ShowDialog(string title, string message)
        {
            await Application.Current.MainPage.DisplayAlert(title, message, "OK");
        }
    }
    }