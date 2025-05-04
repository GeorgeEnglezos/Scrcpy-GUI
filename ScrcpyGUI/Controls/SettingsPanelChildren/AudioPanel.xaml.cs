using System.Data;
using System.Diagnostics;
using ScrcpyGUI.Models;

namespace ScrcpyGUI.Controls
{
    public partial class OptionsAudioPanel : ContentView
    {
        public event EventHandler<string> AudioSettingsChanged;
        private AudioOptions audioSettings = new AudioOptions();
        public OptionsAudioPanel()
        {
            InitializeComponent();
            LoadAudioOptions();
        }

        private void LoadAudioOptions()
        {
            AudioBitRateEntry.Text = audioSettings.AudioBitRate;
            AudioBufferEntry.Text = audioSettings.AudioBuffer;
            AudioDupCheckBox.IsChecked = audioSettings.AudioDup;
            AudioCodecPicker.SelectedItem = audioSettings.AudioCodec;
            AudioCodecOptionsEntry.Text = audioSettings.AudioCodecOptions;
            NoAudioCheckBox.IsChecked = audioSettings.NoAudio;
        }

        private void OnAudioBitRateChanged(object sender, TextChangedEventArgs e)
        {
            audioSettings.AudioBitRate = e.NewTextValue;
            RaiseAudioSettingsChanged();
        }

        private void OnAudioBufferChanged(object sender, TextChangedEventArgs e)
        {
            audioSettings.AudioBuffer = e.NewTextValue;
            RaiseAudioSettingsChanged();
        }

        private void OnAudioDupChanged(object sender, CheckedChangedEventArgs e)
        {
            audioSettings.AudioDup = e.Value;
            RaiseAudioSettingsChanged();
        }
        
        private void OnNoAudioChanged(object sender, CheckedChangedEventArgs e)
        {
            audioSettings.NoAudio = e.Value;
            RaiseAudioSettingsChanged();
        }

        private void OnAudioCodecChanged(object sender, EventArgs e)
        {
            if (AudioCodecPicker.SelectedItem is string selectedCodec)
            {
                audioSettings.AudioCodec = selectedCodec;
                RaiseAudioSettingsChanged();
            }
        }

        private void OnAudioCodecOptionsChanged(object sender, TextChangedEventArgs e)
        {
            audioSettings.AudioCodecOptions = e.NewTextValue;
            RaiseAudioSettingsChanged();
        }

        private void RaiseAudioSettingsChanged()
        {
            AudioSettingsChanged?.Invoke(this, audioSettings.GenerateCommandPart());
        }


        public void CleanSettings(object sender, EventArgs e)
        {
            AudioSettingsChanged?.Invoke(this, "");
            audioSettings = new AudioOptions();
            ResetAllControls();
        }

        private void ResetAllControls()
        {
            // Reset Entries
            AudioBitRateEntry.Text = string.Empty;
            AudioBufferEntry.Text = string.Empty;
            AudioCodecOptionsEntry.Text = string.Empty;

            // Reset CheckBoxes
            AudioDupCheckBox.IsChecked = false;
            NoAudioCheckBox.IsChecked = false;

            // Reset Picker
            AudioCodecPicker.SelectedIndex = -1;
        }
    }
}
