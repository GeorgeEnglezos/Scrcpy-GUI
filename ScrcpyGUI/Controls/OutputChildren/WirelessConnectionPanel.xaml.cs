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

        private async void OnRunTCP(object sender, EventArgs e)
        {
            var port = TcpipEntry.Text?.Trim();
            if (!string.IsNullOrEmpty(port))
            {
                var result = await AdbCmdService.RunTCPPort(port);
                await Application.Current.MainPage.DisplayAlert("TCP Result", result, "OK");
            }
            else
            {
                await Application.Current.MainPage.DisplayAlert("Error", "Please enter a valid port.", "OK");
            }
        }


        private async void OnRunPhoneIp(object sender, EventArgs e)
        {
            var ip = PhoneIpEntry.Text?.Trim();
            if (!string.IsNullOrEmpty(ip))
            {
                var result = await AdbCmdService.RunPhoneIp(ip);
                await Application.Current.MainPage.DisplayAlert("IP Result", result, "OK");
            }
            else
            {
                await Application.Current.MainPage.DisplayAlert("Error", "Please enter a valid IP address.", "OK");
            }
        }

    }
}