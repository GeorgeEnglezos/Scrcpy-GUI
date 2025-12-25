using System.ComponentModel;
using System.Data;
using System.Diagnostics;
using System.Runtime.CompilerServices;
using System.Threading.Tasks;
using ScrcpyGUI.Models;

namespace ScrcpyGUI.Controls
{
    public partial class StatusPanel : ContentView
    {
        public event EventHandler<string> StatusRefreshed;

        private string _adbStatusColor = "Black";
        private string _scrcpyStatusColor = "Black";
        private string _deviceStatusColor = "Black";

        private const string FA_USB = "\uf0c1";
        private const string FA_WIFI = "\uf1eb";
        private const string FA_CHECK_CIRCLE = "\uf058";
        private const string FA_TIMES_CIRCLE = "\uf057";
        private const string GREEN_LIGHT = "#30d56c";
        private const string GREEN_DARK = "#073618";
        private const string RED_LIGHT = "#e95845";
        private const string RED_DARK = "#380505";
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

        public StatusPanel()
        {
            InitializeComponent();
            BindingContext = this;
            PerformInitialChecks();
            StartDeviceWatcher();
            this.SizeChanged += OnSizeChanged;

        }

        private void StartDeviceWatcher()
        {
            Dispatcher.StartTimer(TimeSpan.FromSeconds(5), () =>
            {
                Dispatcher.Dispatch(() =>
                {
                    RefreshStatus();
                });

                return true; // Keep the timer running
            });
        }

        private void OnRefreshStatusClicked(object sender, EventArgs e)
        {
            RefreshStatus();
        }

        private async Task RefreshStatus()
        {
            CheckAdbInstallation();
            CheckScrcpyInstallation();
            CheckDeviceConnection();

            InvokeRefresh("");
        }

        private async Task<string> PerformInitialChecks()
        {
            bool isAdbInstalled = await CheckAdbInstallation();
            bool isScrcpyInstalled = await CheckScrcpyInstallation();
            bool isDeviceConnected = await CheckDeviceConnection();
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

            return finalMessage;
        }
        private async Task<bool> CheckAdbInstallation()
        {
            bool isAdbInstalled = await AdbCmdService.CheckIfAdbIsInstalled();

            var adbFontImageSource = AdbStatusIcon.Source as FontImageSource;

            if (isAdbInstalled)
            {
                AdbStatusLabel.Text = "Yes";
                AdbStatusBorder.Background = Color.FromHex(GREEN_DARK);
                AdbStatusBorder.Stroke = Color.FromHex(GREEN_LIGHT);
                AdbStatusLabel.TextColor = Color.FromHex(GREEN_LIGHT);
                if (adbFontImageSource != null)
                {
                    adbFontImageSource.Glyph = FA_CHECK_CIRCLE;
                    adbFontImageSource.Color = Color.FromHex(GREEN_LIGHT);
                }
            }
            else
            {
                AdbStatusLabel.Text = "No";
                AdbStatusBorder.Background = Color.FromHex(RED_DARK);
                AdbStatusBorder.Stroke = Color.FromHex(RED_LIGHT);
                AdbStatusLabel.TextColor = Color.FromHex(RED_LIGHT);
                if (adbFontImageSource != null)
                {
                    adbFontImageSource.Glyph = FA_TIMES_CIRCLE;
                    adbFontImageSource.Color = Color.FromHex(RED_LIGHT);
                }
            }
            return isAdbInstalled;
        }

        private async Task<bool> CheckScrcpyInstallation()
        {
            bool isScrcpyInstalled = await AdbCmdService.CheckIfScrcpyIsInstalled();
            var scrcpyFontImageSource = ScrcpyStatusIcon.Source as FontImageSource;

            if (isScrcpyInstalled)
            {
                ScrcpyStatusLabel.Text = "Yes";
                ScrcpyStatusBorder.Background = Color.FromHex(GREEN_DARK);
                ScrcpyStatusBorder.Stroke = Color.FromHex(GREEN_LIGHT);
                ScrcpyStatusLabel.TextColor = Color.FromHex(GREEN_LIGHT);
                if (scrcpyFontImageSource != null)
                {
                    scrcpyFontImageSource.Glyph = FA_CHECK_CIRCLE;
                    scrcpyFontImageSource.Color = Color.FromHex(GREEN_LIGHT);
                }
            }
            else
            {
                ScrcpyStatusLabel.Text = "No";
                ScrcpyStatusBorder.Background = Color.FromHex(RED_DARK);
                ScrcpyStatusBorder.Stroke = Color.FromHex(RED_LIGHT);
                ScrcpyStatusLabel.TextColor = Color.FromHex(RED_LIGHT);
                if (scrcpyFontImageSource != null)
                {
                    scrcpyFontImageSource.Glyph = FA_TIMES_CIRCLE;
                    scrcpyFontImageSource.Color = Color.FromHex(RED_LIGHT);
                }
            }
            return isScrcpyInstalled;
        }

        private async Task<bool> CheckDeviceConnection()
        {
            AdbCmdService.ConnectionType deviceConnection = await AdbCmdService.CheckDeviceConnection();
            var deviceFontImageSource = DeviceStatusIcon.Source as FontImageSource; 

            if (deviceConnection == AdbCmdService.ConnectionType.None)
            {
                DeviceStatusLabel.Text = "No";
                DeviceStatusBorder.Background = Color.FromHex(RED_DARK);
                DeviceStatusBorder.Stroke = Color.FromHex(RED_LIGHT);
                DeviceStatusLabel.TextColor = Color.FromHex(RED_LIGHT);
                if (deviceFontImageSource != null)
                {
                    deviceFontImageSource.Glyph = FA_TIMES_CIRCLE;
                    deviceFontImageSource.Color = Color.FromHex(RED_LIGHT);
                }
                return false;
            }
            else
            {
                DeviceStatusLabel.Text = "Yes";
                DeviceStatusBorder.Background = Color.FromHex(GREEN_DARK);
                DeviceStatusBorder.Stroke = Color.FromHex(GREEN_LIGHT);
                DeviceStatusLabel.TextColor = Color.FromHex(GREEN_LIGHT);
                if (deviceFontImageSource != null)
                {
                    deviceFontImageSource.Glyph = deviceConnection == AdbCmdService.ConnectionType.Usb ? FA_USB : FA_WIFI;
                    deviceFontImageSource.Color = Color.FromHex(GREEN_LIGHT);
                }
                return true;
            }
        }

        private void OnSizeChanged(object sender, EventArgs e)
        {
            double breakpointWidth = 670;

            if (Width < breakpointWidth)
            {
                StatusContainerGrid.RowDefinitions.Clear();
                StatusContainerGrid.ColumnDefinitions.Clear();

                StatusContainerGrid.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
                StatusContainerGrid.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
                StatusContainerGrid.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });

                StatusContainerGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Star });

                Grid.SetRow(AdbStatusPanel, 0);
                Grid.SetColumn(AdbStatusPanel, 0);
                AdbStatusBorder.HorizontalOptions = LayoutOptions.End;

                Grid.SetRow(ScrcpyStatusPanel, 1);
                Grid.SetColumn(ScrcpyStatusPanel, 0);
                ScrcpyStatusBorder.HorizontalOptions = LayoutOptions.End;

                Grid.SetRow(DeviceStatusPanel, 2);
                Grid.SetColumn(DeviceStatusPanel, 0);
                DeviceStatusBorder.HorizontalOptions = LayoutOptions.End;

            }
            else
            {
                StatusContainerGrid.RowDefinitions.Clear();
                StatusContainerGrid.ColumnDefinitions.Clear();

                StatusContainerGrid.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });

                StatusContainerGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Star });
                StatusContainerGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Star });
                StatusContainerGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Star });

                Grid.SetRow(AdbStatusPanel, 0);
                Grid.SetColumn(AdbStatusPanel, 0);
                AdbStatusBorder.HorizontalOptions = LayoutOptions.Center;

                Grid.SetRow(ScrcpyStatusPanel, 0);
                Grid.SetColumn(ScrcpyStatusPanel, 1);
                ScrcpyStatusBorder.HorizontalOptions = LayoutOptions.Center;

                Grid.SetRow(DeviceStatusPanel, 0);
                Grid.SetColumn(DeviceStatusPanel, 2);
                DeviceStatusBorder.HorizontalOptions = LayoutOptions.Center;

            }
        }

        private async void InvokeRefresh(string message)
        {
            await Task.Delay(700);

            StatusRefreshed?.Invoke(this, message);
        }
    }
}
