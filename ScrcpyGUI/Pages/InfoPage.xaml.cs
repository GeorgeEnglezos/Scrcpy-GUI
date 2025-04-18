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

        private void CheckAdbInstallation()
        {
            bool isAdbInstalled = AdbCmdService.CheckIfAdbIsInstalled();
            AdbStatusLabel.Text = isAdbInstalled ? "Yes" : "No";
            AdbStatusColor = isAdbInstalled ? "Green" : "Red";
        }

        private void CheckScrcpyInstallation()
        {
            bool isScrcpyInstalled = AdbCmdService.CheckIfScrcpyIsInstalled();
            ScrcpyStatusLabel.Text = isScrcpyInstalled ? "Yes" : "No";
            ScrcpyStatusColor = isScrcpyInstalled ? "Green" : "Red";
        }

        private void CheckDeviceConnection()
        {
            bool isDeviceConnected = AdbCmdService.CheckIfDeviceIsConnected();
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
