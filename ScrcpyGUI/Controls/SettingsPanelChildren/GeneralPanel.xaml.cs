using ScrcpyGUI.Models;
using System.Diagnostics;

namespace ScrcpyGUI.Controls;

public partial class OptionsGeneralPanel : ContentView
{

    public event EventHandler<string> GeneralOptionsChanged;
    private GeneralCastOptions generalSettings = GeneralCastOptions.Instance;

    public OptionsGeneralPanel()
    {
        InitializeComponent();
    }

    private void OnFullscreenCheckedChanged(object sender, CheckedChangedEventArgs e)
    {
        generalSettings.Fullscreen = e.Value;
        OnWindowsCastSettings_Changed();
    }

    private void OnScreenOffCheckedChanged(object sender, CheckedChangedEventArgs e)
    {
        generalSettings.TurnScreenOff = e.Value;
        OnWindowsCastSettings_Changed();
    }

    private void OnCropEntryTextChanged(object sender, TextChangedEventArgs e)
    {
        generalSettings.Crop = e.NewTextValue;
        OnWindowsCastSettings_Changed();
    }
    private void OnVideoOrientationChanged(object sender, EventArgs e)
    {
        if (VideoOrientationPicker.SelectedItem != null)
        {
            generalSettings.VideoOrientation = VideoOrientationPicker.SelectedItem.ToString();
            OnWindowsCastSettings_Changed();
        }
    }

    private void OnStayAwakeCheckedChanged(object sender, CheckedChangedEventArgs e)
    {
        generalSettings.StayAwake = e.Value;
        OnWindowsCastSettings_Changed();
    }

    private void OnWindowTitleEntryTextChanged(object sender, TextChangedEventArgs e)
    {
        generalSettings.WindowTitle = e.NewTextValue;
        OnWindowsCastSettings_Changed();
    }

    private void OnWindowBorderlessCheckedChanged(object sender, CheckedChangedEventArgs e)
    {
        generalSettings.WindowBorderless = e.Value;
        OnWindowsCastSettings_Changed();
    }

    private void OnWindowAlwaysOnTopCheckedChanged(object sender, CheckedChangedEventArgs e)
    {
        generalSettings.WindowAlwaysOnTop = e.Value;
        OnWindowsCastSettings_Changed();
    }

    private void OnDisableScreensaverCheckedChanged(object sender, CheckedChangedEventArgs e)
    {
        generalSettings.DisableScreensaver = e.Value;
        OnWindowsCastSettings_Changed();
    }

    private void OnWindowsCastSettings_Changed()
    {
        GeneralOptionsChanged?.Invoke(this, generalSettings.GenerateCommandPart());
    }

    public void CleanSettings(object sender, EventArgs e)
    {
        GeneralOptionsChanged?.Invoke(this, "");
        generalSettings = new GeneralCastOptions();
        ResetAllControls();
    }

    private void ResetAllControls()
    {
        // Reset CheckBoxes
        FullscreenCheck.IsChecked = false;
        TurnScreenOffCheck.IsChecked = false;
        StayAwakeCheck.IsChecked = false;
        WindowBorderlessCheck.IsChecked = false;
        WindowAlwaysOnTopCheck.IsChecked = false;
        DisableScreensaverCheck.IsChecked = false;

        // Reset Entries
        CropEntry.Text = string.Empty;
        WindowTitleEntry.Text = string.Empty;

        // Reset Picker
        VideoOrientationPicker.SelectedIndex = -1; // This sets it to no selection
    }
}