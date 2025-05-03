using System.Data;
using System.Diagnostics;
using ScrcpyGUI.Models;

namespace ScrcpyGUI.Controls
{
    public partial class OptionsAudioPanel : ContentView
    {
        public event EventHandler<string> AudioSettingsChanged;

        public OptionsAudioPanel()
        {
            InitializeComponent();
            LoadAudioOptions();
        }

        private void LoadAudioOptions()
        {
            var audioOptions = AudioOptions.Instance;
            AudioBitRateEntry.Text = audioOptions.AudioBitRate;
            AudioBufferEntry.Text = audioOptions.AudioBuffer;
            AudioDupCheckBox.IsChecked = audioOptions.AudioDup;
            AudioCodecPicker.SelectedItem = audioOptions.AudioCodec;
            AudioCodecOptionsEntry.Text = audioOptions.AudioCodecOptions;
            NoAudioCheckBox.IsChecked = audioOptions.NoAudio;
        }

        private void OnAudioBitRateChanged(object sender, TextChangedEventArgs e)
        {
            AudioOptions.Instance.AudioBitRate = e.NewTextValue;
            RaiseAudioSettingsChanged();
        }

        private void OnAudioBufferChanged(object sender, TextChangedEventArgs e)
        {
            AudioOptions.Instance.AudioBuffer = e.NewTextValue;
            RaiseAudioSettingsChanged();
        }

        private void OnAudioDupChanged(object sender, CheckedChangedEventArgs e)
        {
            AudioOptions.Instance.AudioDup = e.Value;
            RaiseAudioSettingsChanged();
        }
        
        private void OnNoAudioChanged(object sender, CheckedChangedEventArgs e)
        {
            AudioOptions.Instance.NoAudio = e.Value;
            RaiseAudioSettingsChanged();
        }

        private void OnAudioCodecChanged(object sender, EventArgs e)
        {
            if (AudioCodecPicker.SelectedItem is string selectedCodec)
            {
                AudioOptions.Instance.AudioCodec = selectedCodec;
                RaiseAudioSettingsChanged();
            }
        }

        private void OnAudioCodecOptionsChanged(object sender, TextChangedEventArgs e)
        {
            AudioOptions.Instance.AudioCodecOptions = e.NewTextValue;
            RaiseAudioSettingsChanged();
        }

        private void RaiseAudioSettingsChanged()
        {
            AudioSettingsChanged?.Invoke(this, AudioOptions.Instance.GenerateCommandPart());
        }
    }
}
