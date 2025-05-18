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
            var result = await AdbCmdService.RunAdbCommandAsync(AdbCmdService.CommandEnum.Tcp, "usb");
            await ShowDialog("Stop Connection", result.Output);
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

            string summary = $"Auto-detected IP: {ip}\n\nTCP Result:\n{portResult}\n\nIP Result:\n{ipResult}";
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