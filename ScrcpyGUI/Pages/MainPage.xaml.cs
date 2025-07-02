using Microsoft.Maui.Layouts;
using System.Diagnostics;
using ScrcpyGUI.Controls;
using ScrcpyGUI.Models;
using Microsoft.Maui.Controls;

namespace ScrcpyGUI
{
    //To build the application run
    //dotnet publish -c Release -f net9.0-windows10.0.19041.0 -p:PublishSingleFile=true -p:SelfContained=true -p:PublishTrimmed=true

    public partial class MainPage : ContentPage
    {
        public MainPage()
        {
            InitializeComponent();
            AdbCmdService.scrcpyPath = DataStorage.LoadData().AppSettings.ScrcpyPath;
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

        private async void OnRefreshPage(object? sender, string e)
        {
            AppRefreshed?.Invoke(this, EventArgs.Empty);
        }

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


        // Change the values for every value related to the device
        private async void OnDeviceChanged(object? sender, string e)
        {
            await OptionsPanel.PackageSelector.LoadPackages();
            OptionsPanel.GeneralPanel.ReloadCodecsEncoders();
            OptionsPanel.AudioPanel.ReloadCodecsEncoders();
        }

        //public async void ReloadPage() {
        //    //await Navigation.PushAsync(new MainPage());
        //    //Navigation.RemovePage(this);
        //}
    }
}
