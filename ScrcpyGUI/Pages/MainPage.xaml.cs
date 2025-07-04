using Microsoft.Maui.Layouts;
using System.Diagnostics;
using ScrcpyGUI.Controls;
using ScrcpyGUI.Models;
using Microsoft.Maui.Controls;

namespace ScrcpyGUI
{
    //To build the application run
    //dotnet publish -c Release -f net9.0-windows10.0.19041.0 -p:PublishSingleFile=true
    // THIS PART MIGHT CAUSE ISSUES -p:SelfContained=true -p:PublishTrimmed=true

    public partial class MainPage : ContentPage
    {
        public MainPage()
        {
            InitializeComponent();
            LoadSettings();
        }

        protected override void OnAppearing()
        {
            base.OnAppearing();

            OutputPanel.ApplySavedVisibilitySettings();
            OptionsPanel.ApplySavedVisibilitySettings();
            
            SubscribeToEvents();
            OptionsPanel.SubscribeToEvents();
            OutputPanel.SubscribeToEvents();

            OptionsPanel.SetOutputPanelReferenceFromMainPage(OutputPanel);
            OutputPanel.SetOptionsPanelReferenceFromMainPage(OptionsPanel);
        }

        protected override void OnDisappearing()
        {
            base.OnDisappearing();

            UnsubscribeToEvents();
            OptionsPanel.UnsubscribeToEvents();
            OutputPanel.UnsubscribeToEvents();

            OptionsPanel.Unsubscribe_SetOutputPanelReferenceFromMainPage(OutputPanel);
            OutputPanel.Unsubscribe_SetOptionsPanelReferenceFromMainPage(OptionsPanel);
        }


        private void SubscribeToEvents()
        {
            //OutputPanel.PageRefreshed += OnRefreshPage;
            FixedHeader.DeviceChanged += OnDeviceChanged;
        }

        private void UnsubscribeToEvents()
        {
            FixedHeader.DeviceChanged -= OnDeviceChanged;
        }

        public event EventHandler AppRefreshed;

        private void OnSizeChanged(object sender, EventArgs e)
        {
            if (Width < 1250) // Example threshold for switching layout
            {
                // Switch to 1 column, 2 rows
                MainGrid.ColumnDefinitions.Clear();
                MainGrid.RowDefinitions.Clear();
                MainGrid.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
                MainGrid.RowDefinitions.Add(new RowDefinition { Height = GridLength.Star });

                Grid.SetColumn(OptionsPanel, 0);
                Grid.SetRow(OptionsPanel, 0);

                Grid.SetColumn(OutputPanel, 0);
                Grid.SetRow(OutputPanel, 1); // Assign OutputPanel to the second row
            }
            else
            {
                // Switch to 2 columns, 1 row
                MainGrid.ColumnDefinitions.Clear();
                MainGrid.RowDefinitions.Clear();
                MainGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Star });
                MainGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Star });

                Grid.SetColumn(OptionsPanel, 0);
                Grid.SetRow(OptionsPanel, 0);

                Grid.SetColumn(OutputPanel, 1);
                Grid.SetRow(OutputPanel, 0); // Assign OutputPanel to the first row
            }
        }

        private async void OnDeviceChanged(object? sender, string e)
        {
            await OptionsPanel.PackageSelector.LoadPackages();
            OptionsPanel.GeneralPanel.ReloadCodecsEncoders();
            OptionsPanel.AudioPanel.ReloadCodecsEncoders();
        }

        private async void LoadSettings() {
            DataStorage.staticSavedData = DataStorage.LoadData();
            var settings = DataStorage.staticSavedData.AppSettings;

            AdbCmdService.scrcpyPath = settings.ScrcpyPath;
            AdbCmdService.adbPath = settings.AdbPath;
            AdbCmdService.recordingsPath = settings.RecordingPath ?? Environment.SpecialFolder.Desktop.ToString();
            DataStorage.staticSavedData.AppSettings.DownloadPath = settings.DownloadPath ?? Environment.GetFolderPath(Environment.SpecialFolder.Desktop).ToString();
        }
    }
}
