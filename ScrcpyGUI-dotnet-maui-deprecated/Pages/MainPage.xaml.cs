using Microsoft.Maui.Layouts;
using System.Diagnostics;
using ScrcpyGUI.Controls;
using ScrcpyGUI.Models;
using Microsoft.Maui.Controls;

namespace ScrcpyGUI
{
    /// <summary>
    /// Main page for the Scrcpy-GUI application containing the primary user interface.
    /// DEPRECATED: This .NET MAUI application is being replaced by a Flutter version.
    /// Manages the responsive layout with OptionsPanel and OutputPanel, handles device selection events,
    /// and orchestrates communication between UI components.
    /// </summary>
    /// <remarks>
    /// To build the application run:
    /// dotnet publish -c Release -f net9.0-windows10.0.19041.0 -p:PublishSingleFile=true
    /// Note: -p:SelfContained=true -p:PublishTrimmed=true might cause issues
    /// </remarks>
    public partial class MainPage : ContentPage
    {
        /// <summary>
        /// Initializes a new instance of the MainPage class.
        /// </summary>
        public MainPage()
        {
            InitializeComponent();
        }

        /// <summary>
        /// Called when the page is appearing. Sets up visibility settings, subscribes to events,
        /// establishes cross-panel references, and initializes the Scrcpy path.
        /// </summary>
        protected override void OnAppearing()
        {
            base.OnAppearing();

            OutputPanel.ApplySavedVisibilitySettings();
            OptionsPanel.ApplySavedVisibilitySettings();

            FixedHeader.DeviceChanged += OnDeviceChanged;
            OptionsPanel.SubscribeToEvents();
            OutputPanel.SubscribeToEvents();

            OptionsPanel.SetOutputPanelReferenceFromMainPage(OutputPanel);
            OutputPanel.SetOptionsPanelReferenceFromMainPage(OptionsPanel);

            //There might be changes on the paths
            AdbCmdService.SetScrcpyPath();
        }

        /// <summary>
        /// Called when the page is disappearing. Cleans up event subscriptions and panel references
        /// to prevent memory leaks.
        /// </summary>
        protected override void OnDisappearing()
        {
            base.OnDisappearing();

            FixedHeader.DeviceChanged -= OnDeviceChanged;
            OptionsPanel.UnsubscribeToEvents();
            OutputPanel.UnsubscribeToEvents();

            OptionsPanel.Unsubscribe_SetOutputPanelReferenceFromMainPage(OutputPanel);
            OutputPanel.Unsubscribe_SetOptionsPanelReferenceFromMainPage(OptionsPanel);
        }

        /// <summary>
        /// Event raised when the application needs to be refreshed.
        /// </summary>
        public event EventHandler AppRefreshed;

        /// <summary>
        /// Handles window size changes to implement responsive layout.
        /// Switches between vertical (1 column, 2 rows) and horizontal (2 columns, 1 row) layouts
        /// based on a 1250px width breakpoint.
        /// </summary>
        /// <param name="sender">The event sender.</param>
        /// <param name="e">The event arguments.</param>
        private void OnSizeChanged(object sender, EventArgs e)
        {
            if (Width < 1250)
            {
                // Switch to 1 column, 2 rows
                MainGrid.ColumnDefinitions.Clear();
                MainGrid.RowDefinitions.Clear();
                MainGrid.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
                MainGrid.RowDefinitions.Add(new RowDefinition { Height = GridLength.Star });

                Grid.SetColumn(OptionsPanel, 0);
                Grid.SetRow(OptionsPanel, 0);

                Grid.SetColumn(OutputPanel, 0);
                Grid.SetRow(OutputPanel, 1);
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
                Grid.SetRow(OutputPanel, 0);
            }
        }

        /// <summary>
        /// Handles device selection changes from the header.
        /// Reloads device-specific data including package lists and codec/encoder pairs.
        /// </summary>
        /// <param name="sender">The event sender.</param>
        /// <param name="e">The selected device identifier.</param>
        private async void OnDeviceChanged(object? sender, string e)
        {
            await OptionsPanel.PackageSelector.LoadPackages();
            OptionsPanel.GeneralPanel.ReloadCodecsEncoders();
            OptionsPanel.AudioPanel.ReloadCodecsEncoders();
        }
    }
}
