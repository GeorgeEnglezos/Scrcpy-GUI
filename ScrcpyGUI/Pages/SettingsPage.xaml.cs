using ScrcpyGUI.Controls;
using ScrcpyGUI.Models;
using System;
using System.ComponentModel;
using Microsoft.Maui.Controls;

namespace ScrcpyGUI;

public partial class SettingsPage : ContentPage
{
    ScrcpyGuiData scrcpyData = new ScrcpyGuiData();
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

    protected override void OnAppearing()
    {
        base.OnAppearing();
        scrcpyData = DataStorage.staticSavedData;
    }

    private void OnCommandColorsChanged(object? sender, PropertyChangedEventArgs e)
    {
        scrcpyData.AppSettings.HomeCommandPreviewCommandColors = HomeCommandColorPicker.SelectedItem?.ToString() ?? "None";
        if (HomeCommandColorPicker.SelectedItem == null || string.IsNullOrEmpty(HomeCommandColorPicker.SelectedItem.ToString())) {
            HomeCommandColorPicker.SelectedItem = "None";
        }
    }

    private void OnFavoritesCommandColorsChanged(object? sender, PropertyChangedEventArgs e)
    {
        scrcpyData.AppSettings.FavoritesPageCommandColors = FavoritesCommandColorsPicker.SelectedItem?.ToString() ?? "None";
        if (FavoritesCommandColorsPicker.SelectedItem == null || string.IsNullOrEmpty(FavoritesCommandColorsPicker.SelectedItem.ToString())) {
            FavoritesCommandColorsPicker.SelectedItem = "None";
        }
    }

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

    #region checkboxes
    private void OnCMDChanged(object sender, CheckedChangedEventArgs e)
    {
        scrcpyData.AppSettings.OpenCmds = e.Value;
    }

    private void OnWirelessPanelChanged(object sender, CheckedChangedEventArgs e)
    {
        scrcpyData.AppSettings.HideTcpPanel = e.Value;
    }

    private void OnStatusPanelChanged(object sender, CheckedChangedEventArgs e)
    {
        scrcpyData.AppSettings.HideStatusPanel = e.Value;
    }

    private void OnHideVirtualDisplayPanelChanged(object sender, CheckedChangedEventArgs e)
    {
        scrcpyData.AppSettings.HideVirtualMonitorPanel = e.Value;
    }

    private void OnHideRecordingPanelChanged(object sender, CheckedChangedEventArgs e)
    {
        scrcpyData.AppSettings.HideRecordingPanel = e.Value;
    }

    private void OnHideOutputPanelChanged(object sender, CheckedChangedEventArgs e)
    {
        scrcpyData.AppSettings.HideOutputPanel = e.Value;
    }
    #endregion


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

    private void SaveChanges(object sender, EventArgs e)
    {
        SaveSettings();
        DisplayAlert("Info", $"Changes Saved", "OK");
    }

    private void SaveSettings() {
        DataStorage.SaveData(scrcpyData);
    }

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
