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

    //private void OnSoundCheckedChanged(object sender, CheckedChangedEventArgs e)
    //{
    //    generalSettings.StreamSound = e.Value;
    //    OnWindowsCastSettings_Changed();
    //}
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

    //private void OnShowTapsCheckedChanged(object sender, CheckedChangedEventArgs e)
    //{
    //    generalSettings.ShowTaps = e.Value;
    //    OnWindowsCastSettings_Changed();
    //}

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

    //private void OnWindowPositionEntryTextChanged(object sender, TextChangedEventArgs e)
    //{
    //    generalSettings.WindowPosition = e.NewTextValue;
    //    OnWindowsCastSettings_Changed();
    //}

    //private void OnWindowSizeEntryTextChanged(object sender, TextChangedEventArgs e)
    //{
    //    generalSettings.WindowSize = e.NewTextValue;
    //    OnWindowsCastSettings_Changed();
    //}

    private void OnDisableScreensaverCheckedChanged(object sender, CheckedChangedEventArgs e)
    {
        generalSettings.DisableScreensaver = e.Value;
        OnWindowsCastSettings_Changed();
    }

    private void OnWindowsCastSettings_Changed()
    {
        GeneralOptionsChanged?.Invoke(this, generalSettings.GenerateCommandPart());
    }
}