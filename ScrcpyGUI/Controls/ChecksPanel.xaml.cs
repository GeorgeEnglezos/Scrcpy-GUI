using System.ComponentModel;
using System.Data;
using System.Diagnostics;
using System.Runtime.CompilerServices;
using ScrcpyGUI.Models;

namespace ScrcpyGUI.Controls
{
    public partial class ChecksPanel : ContentView
    {
        public event EventHandler<string> StatusRefreshed;

        private string _adbStatusColor = "Black";
        private string _scrcpyStatusColor = "Black";
        private string _deviceStatusColor = "Black";

        public string AdbStatusColor
        {
            get => _adbStatusColor;
            set { _adbStatusColor = value; OnPropertyChanged(); }
        }

        public string ScrcpyStatusColor
        {
            get => _scrcpyStatusColor;
            set { _scrcpyStatusColor = value; OnPropertyChanged(); }
        }

        public string DeviceStatusColor
        {
            get => _deviceStatusColor;
            set { _deviceStatusColor = value; OnPropertyChanged(); }
        }

        public ChecksPanel()
        {
            InitializeComponent();
            BindingContext = this;
            PerformInitialChecks();
        }

        private void OnRefreshStatusClicked(object sender, EventArgs e)
        {
            RefreshStatus();
        }

        private void RefreshStatus()
        {
            CheckAdbInstallation();
            CheckScrcpyInstallation();
            CheckDeviceConnection();

            InvokeRefresh("");
        }

        private async void PerformInitialChecks()
        {
            bool isAdbInstalled = CheckAdbInstallation();
            bool isScrcpyInstalled = CheckScrcpyInstallation();
            bool isDeviceConnected = CheckDeviceConnection();
            var finalMessage = "";

            if (!isAdbInstalled)
            {
                finalMessage += "ADB is not installed.\n";
            }
            if (!isScrcpyInstalled)
            {
                finalMessage += "Scrcpy is not installed.\n";
            }
            if (!isDeviceConnected)
            {
                finalMessage += "No device connected.\n";
            }

            if(!String.IsNullOrEmpty(finalMessage)) await Application.Current.MainPage.DisplayAlert("Error", finalMessage, "OK");
            else Application.Current.MainPage.DisplayAlert("Info", "Everything looks OK", "OK");

        }

        private bool CheckAdbInstallation()
        {
            bool isAdbInstalled = AdbCmdService.CheckIfAdbIsInstalled();
            AdbStatusLabel.Text = isAdbInstalled ? "Yes" : "No";
            AdbStatusColor = isAdbInstalled ? "Green" : "Red";
            return isAdbInstalled;
        }

        private bool CheckScrcpyInstallation()
        {
            bool isScrcpyInstalled = AdbCmdService.CheckIfScrcpyIsInstalled();
            ScrcpyStatusLabel.Text = isScrcpyInstalled ? "Yes" : "No";
            ScrcpyStatusColor = isScrcpyInstalled ? "Green" : "Red";
            return isScrcpyInstalled;
        }

        private bool CheckDeviceConnection()
        {
            bool isDeviceConnected = AdbCmdService.CheckIfDeviceIsConnected();
            DeviceStatusLabel.Text = isDeviceConnected ? "Yes" : "No";
            DeviceStatusColor = isDeviceConnected ? "Green" : "Red";
            return isDeviceConnected;
        }

        private async void InvokeRefresh(string message)
        {
            await Task.Delay(700);

            StatusRefreshed?.Invoke(this, message);
        }
    }
}
