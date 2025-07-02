using ScrcpyGUI.Controls;
using ScrcpyGUI.Models;
using System;
using System.ComponentModel;
using Microsoft.Maui.Controls;

namespace ScrcpyGUI;

public partial class SettingsPage : ContentPage
{
    ScrcpyGuiData scrcpyData = new ScrcpyGuiData();
    AppSettings settings = new AppSettings();
    public SettingsPage()
    {
        InitializeComponent();

        SaveCommand.SetValue(ToolTipProperties.TextProperty, $"Settings and Commands are saved in\n\n{DataStorage.filePath}");
        scrcpyData = DataStorage.LoadData();
        settings = scrcpyData.AppSettings;

        //Initialize Settings' values for the UI
        InitializeCheckboxValues();
        InitializeFolderPickers();
        
        //Colors
        HomeCommandColorPicker.PropertyChanged += OnCommandColorsChanged;
        FavoritesCommandColorsPicker.PropertyChanged += OnFavoritesCommandColorsChanged;
        this.SizeChanged += OnSizeChanged;
    }

    private void OnCommandColorsChanged(object? sender, PropertyChangedEventArgs e)
    {
        settings.HomeCommandPreviewCommandColors = HomeCommandColorPicker.SelectedItem?.ToString() ?? "None";
        if (HomeCommandColorPicker.SelectedItem == null || string.IsNullOrEmpty(HomeCommandColorPicker.SelectedItem.ToString())) {
            HomeCommandColorPicker.SelectedItem = "None";
        }
    }

    private void OnFavoritesCommandColorsChanged(object? sender, PropertyChangedEventArgs e)
    {
        settings.FavoritesPageCommandColors = FavoritesCommandColorsPicker.SelectedItem?.ToString() ?? "None";
        if (FavoritesCommandColorsPicker.SelectedItem == null || string.IsNullOrEmpty(FavoritesCommandColorsPicker.SelectedItem.ToString())) {
            FavoritesCommandColorsPicker.SelectedItem = "None";
        }
    }

    private void InitializeCheckboxValues()
    {
        CmdCheckbox.IsChecked = settings.OpenCmds;
        WirelessPanelCheckbox.IsChecked = settings.HideTcpPanel;
        StatusPanelCheckbox.IsChecked = settings.HideStatusPanel;
        OutputPanelCheckbox.IsChecked = settings.HideOutputPanel;
        RecordingPanelCheckbox.IsChecked = settings.HideRecordingPanel;
        VirtualMonitorCheckbox.IsChecked = settings.HideVirtualMonitorPanel;
        HomeCommandColorPicker.SelectedItem = settings.HomeCommandPreviewCommandColors;
        FavoritesCommandColorsPicker.SelectedItem = settings.FavoritesPageCommandColors;
    }

    #region checkboxes
    private void OnCMDChanged(object sender, CheckedChangedEventArgs e)
    {
        settings.OpenCmds = e.Value;
    }

    private void OnWirelessPanelChanged(object sender, CheckedChangedEventArgs e)
    {
        settings.HideTcpPanel = e.Value;
    }

    private void OnStatusPanelChanged(object sender, CheckedChangedEventArgs e)
    {
        settings.HideStatusPanel = e.Value;
    }

    private void OnHideVirtualDisplayPanelChanged(object sender, CheckedChangedEventArgs e)
    {
        settings.HideVirtualMonitorPanel = e.Value;
    }

    private void OnHideRecordingPanelChanged(object sender, CheckedChangedEventArgs e)
    {
        settings.HideRecordingPanel = e.Value;
    }

    private void OnHideOutputPanelChanged(object sender, CheckedChangedEventArgs e)
    {
        settings.HideOutputPanel = e.Value;
    }
    #endregion


    private void InitializeFolderPickers()
    {
        // Load current paths and set them as initial values
        scrcpyFolderPicker.InitialFolder = scrcpyData.AppSettings.ScrcpyPath;
        downloadFolderPicker.InitialFolder = scrcpyData.AppSettings.DownloadPath; 
        adbFolderPicker.InitialFolder = scrcpyData.AppSettings.AdbPath; 
        settingsFolderPicker.InitialFolder = scrcpyData.AppSettings.SettingsDataPath; 
        recordingFolderPicker.InitialFolder = scrcpyData.AppSettings.RecordingPath;

        // Set up the callback for folder selection
        scrcpyFolderPicker.OnFolderSelected = OnFolderSelected;
        downloadFolderPicker.OnFolderSelected = OnFolderSelected;
        recordingFolderPicker.OnFolderSelected = OnFolderSelected;
        adbFolderPicker.OnFolderSelected = OnFolderSelected;
        settingsFolderPicker.OnFolderSelected = OnFolderSelected;
    }

    private void OnFolderSelected(string selectedFolder, FolderSelector.FolderSelectorType folderType)
    {
        // Handle folder selection based on type
        string pathTypeName = folderType switch
        {
            FolderSelector.FolderSelectorType.ScrcpyPath => "Scrcpy",
            FolderSelector.FolderSelectorType.DownloadPath => "Download",
            FolderSelector.FolderSelectorType.RecordingPath => "Recording",
            FolderSelector.FolderSelectorType.AdbPath => "Adb",
            FolderSelector.FolderSelectorType.SettingsDataPath => "Settings",
            _ => "Unknown"
        };

        // Save to preferences with appropriate key
        string preferenceKey = $"{folderType}Path";
        Preferences.Set(preferenceKey, selectedFolder);

        // Show confirmation to user
        DisplayAlert("Path Updated", $"{pathTypeName} path has been updated to:\n{selectedFolder}", "OK");

        // Update settings based on folder type
        UpdateSettingsForFolderType(folderType, selectedFolder);

        SaveSettings();
    }

    private void UpdateSettingsForFolderType(FolderSelector.FolderSelectorType folderType, string selectedFolder)
    {
        switch (folderType)
        {
            case FolderSelector.FolderSelectorType.ScrcpyPath:
                settings.ScrcpyPath = selectedFolder;
                AdbCmdService.scrcpyPath = selectedFolder;
                break;
            case FolderSelector.FolderSelectorType.DownloadPath:
                settings.DownloadPath = selectedFolder;
                AdbCmdService.commandDownloadPath = selectedFolder;
                break;
            case FolderSelector.FolderSelectorType.AdbPath:
                settings.AdbPath = selectedFolder;
                AdbCmdService.adbPath = selectedFolder;
                break;
            case FolderSelector.FolderSelectorType.SettingsDataPath:
                settings.SettingsDataPath = selectedFolder;
                AdbCmdService.settingsDataPath = selectedFolder;
                break;
            case FolderSelector.FolderSelectorType.RecordingPath:
                settings.RecordingPath = selectedFolder;
                AdbCmdService.recordingsPath = selectedFolder;
                break;
        }
    }

    private void SaveChanges(object sender, EventArgs e)
    {
        SaveSettings();
        DisplayAlert("Info", $"Changes Saved", "OK");
    }

    private void SaveSettings() {
        scrcpyData = DataStorage.LoadData();
        scrcpyData.AppSettings = settings;
        DataStorage.SaveData(scrcpyData);
    }

    private void OnSizeChanged(object sender, EventArgs e)
    {
        double breakpointWidth = 880;

        if (Width < breakpointWidth) // Switch to vertical layout (stacked)
        {
            ResponsiveGrid.RowDefinitions.Clear();
            ResponsiveGrid.ColumnDefinitions.Clear();

            // Set up vertical layout: 2 rows, 1 column
            ResponsiveGrid.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
            ResponsiveGrid.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
            ResponsiveGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Star });

            // Position panels vertically
            Grid.SetRow(SettingsPanel, 0);
            Grid.SetColumn(SettingsPanel, 0);
            Grid.SetRow(FolderSelectorsPanel, 1);
            Grid.SetColumn(FolderSelectorsPanel, 0);
        }
        else // Horizontal layout (side by side)
        {
            ResponsiveGrid.RowDefinitions.Clear();
            ResponsiveGrid.ColumnDefinitions.Clear();

            // Set up horizontal layout: 1 row, 2 columns
            ResponsiveGrid.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
            ResponsiveGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Star });
            ResponsiveGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Star });

            // Position panels side by side
            Grid.SetRow(SettingsPanel, 0);
            Grid.SetColumn(SettingsPanel, 0);
            Grid.SetRow(FolderSelectorsPanel, 0);
            Grid.SetColumn(FolderSelectorsPanel, 1);
        }
    }

}
