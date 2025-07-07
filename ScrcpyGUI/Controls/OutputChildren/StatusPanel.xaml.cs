using System.ComponentModel;
using System.Data;
using System.Diagnostics;
using System.Runtime.CompilerServices;
using ScrcpyGUI.Models;

namespace ScrcpyGUI.Controls
{
    public partial class StatusPanel : ContentView
    {
        public event EventHandler<string> StatusRefreshed;

        private string _adbStatusColor = "Black";
        private string _scrcpyStatusColor = "Black";
        private string _deviceStatusColor = "Black";

        private const string FA_CHECK_CIRCLE = "\uf058"; // fa-check-circle
        private const string FA_TIMES_CIRCLE = "\uf057"; // fa-times-circle
        private const string GREEN_LIGHT = "#30d56c"; // fa-times-circle
        private const string GREEN_DARK = "#073618"; // fa-times-circle
        private const string RED_LIGHT = "#e95845"; // fa-times-circle
        private const string RED_DARK = "#380505"; // fa-times-circle
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

        private void RefreshStatus()
        {
            CheckAdbInstallation();
            CheckScrcpyInstallation();
            CheckDeviceConnection();

            InvokeRefresh("");
        }

        private async void PerformInitialChecks()
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

            if(!String.IsNullOrEmpty(finalMessage)) await Application.Current.MainPage.DisplayAlert("Error", finalMessage, "OK");
            else Application.Current.MainPage.DisplayAlert("Info", "Everything looks OK", "OK");

        }
        // --- ADB Installation Check ---
        private async Task<bool> CheckAdbInstallation()
        {
            bool isAdbInstalled = await AdbCmdService.CheckIfAdbIsInstalled();

            // Get the FontImageSource from the Image.Source
            var adbFontImageSource = AdbStatusIcon.Source as FontImageSource;

            if (isAdbInstalled)
            {
                AdbStatusLabel.Text = "Yes";
                AdbStatusBorder.Background = Color.FromHex(GREEN_DARK); // Dark green background
                AdbStatusBorder.Stroke = Color.FromHex(GREEN_LIGHT); // Lighter green border stroke
                AdbStatusLabel.TextColor = Color.FromHex(GREEN_LIGHT); // Lighter green text color
                if (adbFontImageSource != null)
                {
                    adbFontImageSource.Glyph = FA_CHECK_CIRCLE; // Set the check icon
                    adbFontImageSource.Color = Color.FromHex(GREEN_LIGHT); // Lighter green icon color
                }
            }
            else
            {
                AdbStatusLabel.Text = "No";
                AdbStatusBorder.Background = Color.FromHex(RED_DARK); // Dark red background
                AdbStatusBorder.Stroke = Color.FromHex(RED_LIGHT); // Lighter red border stroke
                AdbStatusLabel.TextColor = Color.FromHex(RED_LIGHT); // Lighter red text color
                if (adbFontImageSource != null)
                {
                    adbFontImageSource.Glyph = FA_TIMES_CIRCLE; // Set the cross icon
                    adbFontImageSource.Color = Color.FromHex(RED_LIGHT); // Lighter red icon color
                }
            }
            return isAdbInstalled;
        }

        private async Task<bool> CheckScrcpyInstallation()
        {
            bool isScrcpyInstalled = await AdbCmdService.CheckIfScrcpyIsInstalled();
            var scrcpyFontImageSource = ScrcpyStatusIcon.Source as FontImageSource; // Get the image source

            if (isScrcpyInstalled)
            {
                ScrcpyStatusLabel.Text = "Yes";
                ScrcpyStatusBorder.Background = Color.FromHex(GREEN_DARK);
                ScrcpyStatusBorder.Stroke = Color.FromHex(GREEN_LIGHT);
                ScrcpyStatusLabel.TextColor = Color.FromHex(GREEN_LIGHT);
                if (scrcpyFontImageSource != null) // Set Glyph and Color for the icon
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
                if (scrcpyFontImageSource != null) // Set Glyph and Color for the icon
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
            var deviceFontImageSource = DeviceStatusIcon.Source as FontImageSource; // Get the image source

            if (deviceConnection == AdbCmdService.ConnectionType.None)
            {
                DeviceStatusLabel.Text = "No";
                DeviceStatusBorder.Background = Color.FromHex(RED_DARK);
                DeviceStatusBorder.Stroke = Color.FromHex(RED_LIGHT);
                DeviceStatusLabel.TextColor = Color.FromHex(RED_LIGHT);
                if (deviceFontImageSource != null) // Set Glyph and Color for the icon
                {
                    deviceFontImageSource.Glyph = FA_TIMES_CIRCLE;
                    deviceFontImageSource.Color = Color.FromHex(RED_LIGHT);
                }
                return false;
            }
            else
            {
                // Note: Your original example had "Yes (USB)" : "Yes (TCP)" for DeviceStatusLabel.Text
                // I'm keeping that logic.
                DeviceStatusLabel.Text = deviceConnection == AdbCmdService.ConnectionType.Usb ? "Yes (USB)" : "Yes (TCP)";
                DeviceStatusBorder.Background = Color.FromHex(GREEN_DARK);
                DeviceStatusBorder.Stroke = Color.FromHex(GREEN_LIGHT);
                DeviceStatusLabel.TextColor = Color.FromHex(GREEN_LIGHT);
                if (deviceFontImageSource != null) // Set Glyph and Color for the icon
                {
                    deviceFontImageSource.Glyph = FA_CHECK_CIRCLE;
                    deviceFontImageSource.Color = Color.FromHex(GREEN_LIGHT);
                }
                return true;
            }
        }

        private void OnSizeChanged(object sender, EventArgs e)
        {
            double breakpointWidth = 670; // Define your breakpoint width

            // Check the current width of the page
            if (Width < breakpointWidth) // Switch to vertical layout (stacked)
            {
                // Clear existing definitions
                StatusContainerGrid.RowDefinitions.Clear();
                StatusContainerGrid.ColumnDefinitions.Clear();

                // Define 3 rows for a stacked layout
                StatusContainerGrid.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
                StatusContainerGrid.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
                StatusContainerGrid.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });

                // Define a single column that takes all available width
                StatusContainerGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Star });

                // Position panels vertically within the StatusContainerGrid
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
            else // Horizontal layout (side by side)
            {
                // Clear existing definitions
                StatusContainerGrid.RowDefinitions.Clear();
                StatusContainerGrid.ColumnDefinitions.Clear();

                // Define a single row for a horizontal layout
                StatusContainerGrid.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });

                // Define 3 columns for side-by-side layout, distributing space equally
                StatusContainerGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Star });
                StatusContainerGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Star });
                StatusContainerGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Star });

                // Position panels side by side within the StatusContainerGrid
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
