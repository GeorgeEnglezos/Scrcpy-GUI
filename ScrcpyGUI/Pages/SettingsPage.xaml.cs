using ScrcpyGUI.Controls;
using ScrcpyGUI.Models;
using System;
using System.ComponentModel;

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
        InitializeCheckboxValues();

        HomeCommandColorPicker.PropertyChanged += OnCommandColorsChanged;
        FavoritesCommandColorsPicker.PropertyChanged += OnFavoritesCommandColorsChanged;
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

    private void SaveChanges(object sender, EventArgs e)
    {
        scrcpyData = DataStorage.LoadData();
        scrcpyData.AppSettings = settings;
        DataStorage.SaveData(scrcpyData);
        DisplayAlert("Info", $"Changes Saved", "OK");
    }
}
