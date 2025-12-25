using ScrcpyGUI.Controls;
using ScrcpyGUI.Models;
using System;
using System.ComponentModel;
using Microsoft.Maui.Controls;

namespace ScrcpyGUI;

/// <summary>
/// Settings page for configuring application behavior and file paths.
/// DEPRECATED: This .NET MAUI application is being replaced by a Flutter version.
/// Manages UI visibility preferences, folder paths for Scrcpy/recording/downloads,
/// and command coloring options.
/// </summary>
public partial class SettingsPage : ContentPage
{
    ScrcpyGuiData scrcpyData = new ScrcpyGuiData();

    /// <summary>
    /// Initializes a new instance of the SettingsPage class.
    /// Loads saved settings, initializes UI controls, and subscribes to change events.
    /// </summary>
    public SettingsPage()
    {
        InitializeComponent();
        //Load settings from data storage
        scrcpyData = DataStorage.staticSavedData;

        //Initialize Settings' values for the UI
        InitializeCheckboxValues();
        InitializeFolderPickers();

        //Colors
        HomeCommandColorPicker.PropertyChanged += OnCommandColorsChanged;
        FavoritesCommandColorsPicker.PropertyChanged += OnFavoritesCommandColorsChanged;
        this.SizeChanged += OnSizeChanged;
    }

    /// <summary>
    /// Called when the page is appearing. Reloads the latest saved data from storage.
    /// </summary>
    protected override void OnAppearing()
    {
        base.OnAppearing();
        scrcpyData = DataStorage.staticSavedData;
    }

    /// <summary>
    /// Handles changes to the home page command color picker.
    /// Updates the color scheme setting for command preview on the home page.
    /// </summary>
    /// <param name="sender">The event sender.</param>
    /// <param name="e">Property changed event arguments.</param>
    private void OnCommandColorsChanged(object? sender, PropertyChangedEventArgs e)
    {
        scrcpyData.AppSettings.HomeCommandPreviewCommandColors = HomeCommandColorPicker.SelectedItem?.ToString() ?? "None";
        if (HomeCommandColorPicker.SelectedItem == null || string.IsNullOrEmpty(HomeCommandColorPicker.SelectedItem.ToString())) {
            HomeCommandColorPicker.SelectedItem = "None";
        }
    }

    /// <summary>
    /// Handles changes to the favorites page command color picker.
    /// Updates the color scheme setting for saved commands display.
    /// </summary>
    /// <param name="sender">The event sender.</param>
    /// <param name="e">Property changed event arguments.</param>
    private void OnFavoritesCommandColorsChanged(object? sender, PropertyChangedEventArgs e)
    {
        scrcpyData.AppSettings.FavoritesPageCommandColors = FavoritesCommandColorsPicker.SelectedItem?.ToString() ?? "None";
        if (FavoritesCommandColorsPicker.SelectedItem == null || string.IsNullOrEmpty(FavoritesCommandColorsPicker.SelectedItem.ToString())) {
            FavoritesCommandColorsPicker.SelectedItem = "None";
        }
    }

    /// <summary>
    /// Initializes all checkbox values from saved application settings.
    /// Sets UI state for panel visibility toggles and color picker selections.
    /// </summary>
    private void InitializeCheckboxValues()
    {
        //CmdCheckbox.IsChecked = scrcpyData.AppSettings.OpenCmds;
        WirelessPanelCheckbox.IsChecked = scrcpyData.AppSettings.HideTcpPanel;
        StatusPanelCheckbox.IsChecked = scrcpyData.AppSettings.HideStatusPanel;
        OutputPanelCheckbox.IsChecked = scrcpyData.AppSettings.HideOutputPanel;
        RecordingPanelCheckbox.IsChecked = scrcpyData.AppSettings.HideRecordingPanel;
        VirtualMonitorCheckbox.IsChecked = scrcpyData.AppSettings.HideVirtualMonitorPanel;
        HomeCommandColorPicker.SelectedItem = scrcpyData.AppSettings.HomeCommandPreviewCommandColors;
        FavoritesCommandColorsPicker.SelectedItem = scrcpyData.AppSettings.FavoritesPageCommandColors;
    }

    #region Checkbox Event Handlers
    /// <summary>
    /// Handles changes to the CMD visibility checkbox.
    /// </summary>
    private void OnCMDChanged(object sender, CheckedChangedEventArgs e)
    {
        scrcpyData.AppSettings.OpenCmds = e.Value;
    }

    /// <summary>
    /// Handles changes to the wireless panel visibility checkbox.
    /// </summary>
    private void OnWirelessPanelChanged(object sender, CheckedChangedEventArgs e)
    {
        scrcpyData.AppSettings.HideTcpPanel = e.Value;
    }

    /// <summary>
    /// Handles changes to the status panel visibility checkbox.
    /// </summary>
    private void OnStatusPanelChanged(object sender, CheckedChangedEventArgs e)
    {
        scrcpyData.AppSettings.HideStatusPanel = e.Value;
    }

    /// <summary>
    /// Handles changes to the virtual display panel visibility checkbox.
    /// </summary>
    private void OnHideVirtualDisplayPanelChanged(object sender, CheckedChangedEventArgs e)
    {
        scrcpyData.AppSettings.HideVirtualMonitorPanel = e.Value;
    }

    /// <summary>
    /// Handles changes to the recording panel visibility checkbox.
    /// </summary>
    private void OnHideRecordingPanelChanged(object sender, CheckedChangedEventArgs e)
    {
        scrcpyData.AppSettings.HideRecordingPanel = e.Value;
    }

    /// <summary>
    /// Handles changes to the output panel visibility checkbox.
    /// </summary>
    private void OnHideOutputPanelChanged(object sender, CheckedChangedEventArgs e)
    {
        scrcpyData.AppSettings.HideOutputPanel = e.Value;
    }
    #endregion


    /// <summary>
    /// Initializes folder picker controls with saved path values.
    /// Sets up callbacks for folder selection events.
    /// </summary>
    private void InitializeFolderPickers()
    {
        // Load current paths and set them as initial values
        scrcpyFolderPicker.InitialFolder = scrcpyData.AppSettings.ScrcpyPath;
        downloadFolderPicker.InitialFolder = scrcpyData.AppSettings.DownloadPath;
        settingsFolderPicker.InitialFolder = Path.Combine(FileSystem.AppDataDirectory, "ScrcpyGui-Data.json");
        recordingFolderPicker.InitialFolder = scrcpyData.AppSettings.RecordingPath;

        // Set up the callback for folder selection
        scrcpyFolderPicker.OnFolderSelected = OnFolderSelected;
        downloadFolderPicker.OnFolderSelected = OnFolderSelected;
        recordingFolderPicker.OnFolderSelected = OnFolderSelected;
        settingsFolderPicker.OnFolderSelected = OnFolderSelected;
    }

    /// <summary>
    /// Handles folder selection events from folder picker controls.
    /// Updates settings, saves changes, and displays confirmation to user.
    /// </summary>
    /// <param name="selectedFolder">The path selected by the user.</param>
    /// <param name="folderType">The type of folder being configured.</param>
    private void OnFolderSelected(string selectedFolder, FolderSelector.FolderSelectorType folderType)
    {
        // Handle folder selection based on type
        string pathTypeName = folderType switch
        {
            FolderSelector.FolderSelectorType.ScrcpyPath => "Scrcpy",
            FolderSelector.FolderSelectorType.DownloadPath => "Download",
            FolderSelector.FolderSelectorType.RecordingPath => "Recording",
            _ => "Unknown"
        };

        UpdateSettingsForFolderType(folderType, selectedFolder);

        SaveSettings();

        DisplayAlert("Path Updated", $"{pathTypeName} path has been updated to:\n{selectedFolder}", "OK");
    }

    /// <summary>
    /// Updates the appropriate setting based on folder type.
    /// </summary>
    /// <param name="folderType">The type of folder being configured.</param>
    /// <param name="selectedFolder">The selected folder path.</param>
    private void UpdateSettingsForFolderType(FolderSelector.FolderSelectorType folderType, string selectedFolder)
    {
        switch (folderType)
        {
            case FolderSelector.FolderSelectorType.ScrcpyPath:
                scrcpyData.AppSettings.ScrcpyPath = selectedFolder;
                break;
            case FolderSelector.FolderSelectorType.DownloadPath:
                scrcpyData.AppSettings.DownloadPath = selectedFolder;
                break;
            case FolderSelector.FolderSelectorType.RecordingPath:
                scrcpyData.AppSettings.RecordingPath = selectedFolder;
                break;
        }
    }

    /// <summary>
    /// Handles the Save Changes button click event.
    /// Persists all settings and displays confirmation dialog.
    /// </summary>
    private void SaveChanges(object sender, EventArgs e)
    {
        SaveSettings();
        DisplayAlert("Info", $"Changes Saved", "OK");
    }

    /// <summary>
    /// Saves the current settings to persistent storage.
    /// </summary>
    private void SaveSettings() {
        DataStorage.SaveData(scrcpyData);
    }

    /// <summary>
    /// Handles window size changes to implement responsive layout.
    /// Switches between vertical and horizontal layouts based on a 950px width breakpoint.
    /// </summary>
    /// <param name="sender">The event sender.</param>
    /// <param name="e">The event arguments.</param>
    private void OnSizeChanged(object sender, EventArgs e)
    {
        double breakpointWidth = 950;
        if (Width < breakpointWidth) // Switch to vertical layout (stacked)
        {
            ResponsiveGrid.RowDefinitions.Clear();
            ResponsiveGrid.ColumnDefinitions.Clear();

            ResponsiveGrid.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
            ResponsiveGrid.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
            ResponsiveGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Star });

            // Position panels vertically
            Grid.SetRow(SettingsPanel, 0);
            Grid.SetColumn(SettingsPanel, 0);
            Grid.SetRow(FolderBorder, 1);  // Now you can reference it directly
            Grid.SetColumn(FolderBorder, 0);
        }
        else // Horizontal layout (side by side)
        {
            ResponsiveGrid.RowDefinitions.Clear();
            ResponsiveGrid.ColumnDefinitions.Clear();

            ResponsiveGrid.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
            ResponsiveGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(45, GridUnitType.Star) });
            ResponsiveGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(55, GridUnitType.Star) });

            // Position panels side by side
            Grid.SetRow(SettingsPanel, 0);
            Grid.SetColumn(SettingsPanel, 0);
            Grid.SetRow(FolderBorder, 0);
            Grid.SetColumn(FolderBorder, 1);
        }
    }
}
