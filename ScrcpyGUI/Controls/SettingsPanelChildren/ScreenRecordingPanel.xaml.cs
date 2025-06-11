using ScrcpyGUI.Models;

namespace ScrcpyGUI.Controls;

public partial class OptionsScreenRecordingPanel : ContentView
{

    public event EventHandler<string> ScreenRecordingOptionsChanged;

    private ScreenRecordingOptions screenRecordingOptions = new ScreenRecordingOptions();

    public OptionsScreenRecordingPanel()
    {
        InitializeComponent();
    }

    public void SubscribeToEvents()
    {
        OutputFormatPicker.PropertyChanged += OnOutputFormatChanged;
    }

    public void UnsubscribeToEvents()
        {
        OutputFormatPicker.PropertyChanged -= OnOutputFormatChanged;
    }

    private void OnEnableRecordingCheckedChanged(object sender, CheckedChangedEventArgs e)
    {
        if (!e.Value)
        {
            ScreenRecordingOptions_Changed();

            ResolutionEntry.Text = string.Empty;
            FramerateEntry.Text = string.Empty;
            OutputFormatPicker.SelectedItem = null;
            screenRecordingOptions.OutputFormat = null;

            OutputFileEntry.Text = string.Empty;
        }
    }

    private void OnResolutionChanged(object sender, TextChangedEventArgs e)
    {
        screenRecordingOptions.MaxSize = e.NewTextValue;
        ScreenRecordingOptions_Changed();
    }

    private void OnFramerateChanged(object sender, TextChangedEventArgs e)
    {
        screenRecordingOptions.Framerate = e.NewTextValue;
        ScreenRecordingOptions_Changed();
    }

    private void OnOutputFormatChanged(object sender, EventArgs e)
    {
        screenRecordingOptions.OutputFormat = OutputFormatPicker.SelectedItem?.ToString() ?? "";
        ScreenRecordingOptions_Changed();
    }

    private void OnOutputFileChanged(object sender, TextChangedEventArgs e)
    {
        screenRecordingOptions.OutputFile = e.NewTextValue;
        ScreenRecordingOptions_Changed();
    }

    private void ScreenRecordingOptions_Changed()
    {
        ScreenRecordingOptionsChanged?.Invoke(this, screenRecordingOptions.GenerateCommandPart());
    }

    public void CleanSettings(object sender, EventArgs e)
    {
        ScreenRecordingOptionsChanged?.Invoke(this, "");
        screenRecordingOptions = new ScreenRecordingOptions();
        ResetAllControls();
    }

    private void ResetAllControls()
    {
        // Reset Entries
        ResolutionEntry.Text = string.Empty;
        FramerateEntry.Text = string.Empty;
        OutputFileEntry.Text = string.Empty;

        // Reset Picker
        screenRecordingOptions.OutputFormat = "";
        OutputFormatPicker.SelectedIndex = -1;
    }
}

