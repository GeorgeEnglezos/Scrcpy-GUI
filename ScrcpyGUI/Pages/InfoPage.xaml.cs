using Microsoft.Maui.Layouts;
using System.ComponentModel;
using System.Runtime.CompilerServices;
using System.Diagnostics;

namespace ScrcpyGUI
{
    public partial class InfoPage : ContentPage, INotifyPropertyChanged
    {
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

        public InfoPage()
        {
            InitializeComponent();
            BindingContext = this;
            RefreshStatus();
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
        }
        private async Task CheckAdbInstallation()
        {
            bool isAdbInstalled = await AdbCmdService.CheckIfAdbIsInstalled();
            AdbStatusLabel.Text = isAdbInstalled ? "Yes" : "No";
            AdbStatusColor = isAdbInstalled ? "Green" : "Red";
        }

        private async Task CheckScrcpyInstallation()
        {
            bool isScrcpyInstalled = await AdbCmdService.CheckIfScrcpyIsInstalled();
            ScrcpyStatusLabel.Text = isScrcpyInstalled ? "Yes" : "No";
            ScrcpyStatusColor = isScrcpyInstalled ? "Green" : "Red";
        }

        private async Task CheckDeviceConnection()
        {
            bool isDeviceConnected = await AdbCmdService.CheckIfDeviceIsConnected();
            DeviceStatusLabel.Text = isDeviceConnected ? "Yes" : "No";
            DeviceStatusColor = isDeviceConnected ? "Green" : "Red";
        }


        public event PropertyChangedEventHandler PropertyChanged;

        protected virtual void OnPropertyChanged([CallerMemberName] string propertyName = null)
        {
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
        }
    }
}
