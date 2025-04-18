using ScrcpyGUI.Models;

namespace ScrcpyGUI.Controls;

public partial class OptionsScreenRecordingPanel : ContentView
{

        public event EventHandler<string> ScreenRecordingOptionsChanged;

        private ScreenRecordingOptions screenRecordingOptions = ScreenRecordingOptions.Instance;

        public OptionsScreenRecordingPanel()
        {
            InitializeComponent();
        }

        private void OnEnableRecordingCheckedChanged(object sender, CheckedChangedEventArgs e)
        {
            if (!e.Value) // If the checkbox is unchecked
            {
                // Reset all options to their default values

                // Notify listeners about the reset
                ScreenRecordingOptions_Changed();

                // Optionally, clear the UI fields
                ResolutionEntry.Text = string.Empty;
                BitrateEntry.Text = string.Empty;
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

        private void OnBitrateChanged(object sender, TextChangedEventArgs e)
        {
        screenRecordingOptions.Bitrate = e.NewTextValue;
            ScreenRecordingOptions_Changed();
        }

        private void OnFramerateChanged(object sender, TextChangedEventArgs e)
        {
            screenRecordingOptions.Framerate = e.NewTextValue;
            ScreenRecordingOptions_Changed();
        }

        private void OnOutputFormatChanged(object sender, EventArgs e)
        {
            if (OutputFormatPicker.SelectedItem != null)
            {
                screenRecordingOptions.OutputFormat = OutputFormatPicker.SelectedItem.ToString();
                ScreenRecordingOptions_Changed();
            }
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
}

