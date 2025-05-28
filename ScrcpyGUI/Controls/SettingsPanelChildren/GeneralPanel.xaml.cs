using ScrcpyGUI.Models;
using System.ComponentModel;
using System.Diagnostics;
using UraniumUI.Material.Controls;

namespace ScrcpyGUI.Controls;

public partial class OptionsGeneralPanel : ContentView
{

    public event EventHandler<string> GeneralOptionsChanged;
    private GeneralCastOptions generalSettings = new GeneralCastOptions();

    public OptionsGeneralPanel()
    {
        InitializeComponent();
        VideoOrientationPicker.PropertyChanged += OnVideoOrientationChanged;
        VideoCodecEncoderPicker.PropertyChanged += OnVideoCodecEncoderChanged;
        VideoCodecEncoderPicker.ItemsSource = AdbCmdService.selectedDevice.VideoCodecEncoderPairs;
    }

    private void OnVideoOrientationChanged(object sender, PropertyChangedEventArgs e)
    {
        generalSettings.VideoOrientation = VideoOrientationPicker.SelectedItem?.ToString() ?? "";
        OnGenericSettings_Changed();
    }
    
    private void OnVideoCodecEncoderChanged(object sender, PropertyChangedEventArgs e)
    {
        generalSettings.VideoCodecEncoderPair = VideoCodecEncoderPicker.SelectedItem?.ToString() ?? "";
        OnGenericSettings_Changed();
    }

    //Checkboxes
    #region checkboxes
    private void OnFullscreenCheckboxChanged(object sender, EventArgs e)
    {
        var checkBox = sender as InputKit.Shared.Controls.CheckBox;
        generalSettings.Fullscreen = checkBox?.IsChecked ?? false;
        OnGenericSettings_Changed();
    }

    private void OnScreenOffCheckboxChanged(object sender, EventArgs e)
    {
        var checkBox = sender as InputKit.Shared.Controls.CheckBox;
        generalSettings.TurnScreenOff = checkBox?.IsChecked ?? false;
        OnGenericSettings_Changed();
    }
    private void OnStayAwakeCheckboxChanged(object sender, EventArgs e)
    {
        var checkBox = sender as InputKit.Shared.Controls.CheckBox;
        generalSettings.StayAwake = checkBox?.IsChecked ?? false;
        OnGenericSettings_Changed();
    }
    private void OnBorderlessCheckboxChanged(object sender, EventArgs e)
    {
        var checkBox = sender as InputKit.Shared.Controls.CheckBox;
        generalSettings.WindowBorderless = checkBox?.IsChecked ?? false;
        OnGenericSettings_Changed();
    }

    private void OnWindowAlwaysOnTopCheckboxChanged(object sender, EventArgs e)
    {
        var checkBox = sender as InputKit.Shared.Controls.CheckBox;
        generalSettings.WindowAlwaysOnTop = checkBox?.IsChecked ?? false;
        OnGenericSettings_Changed();
    }

    private void OnDisableScreensaverCheckboxChanged(object sender, EventArgs e)
    {
        var checkBox = sender as InputKit.Shared.Controls.CheckBox;
        generalSettings.DisableScreensaver = checkBox?.IsChecked ?? false;
        OnGenericSettings_Changed();
    }

    #endregion

    private void OnCropEntryTextChanged(object sender, TextChangedEventArgs e)
    {
        generalSettings.Crop = e.NewTextValue;
        OnGenericSettings_Changed();
    }
    
    private void OnExtraParametersEntryTextChanged(object sender, TextChangedEventArgs e)
    {
        generalSettings.ExtraParameters = e.NewTextValue;
        OnGenericSettings_Changed();
    }

    private void OnWindowTitleEntryTextChanged(object sender, TextChangedEventArgs e)
    {
        generalSettings.WindowTitle = e.NewTextValue;
        OnGenericSettings_Changed();
    }

    private void OnGenericSettings_Changed()
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
        ExtraParameterEntry.Text = string.Empty;

        // Reset Picker
        VideoOrientationPicker.SelectedIndex = -1; // This sets it to no selection
        generalSettings.VideoOrientation = "";
        VideoCodecEncoderPicker.SelectedIndex = -1; // This sets it to no selection
        generalSettings.VideoCodecEncoderPair = "";
    }
}