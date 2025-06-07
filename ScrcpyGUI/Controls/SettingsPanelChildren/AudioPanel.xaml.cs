using ScrcpyGUI.Models;
using System.ComponentModel;
using System.Diagnostics;
using UraniumUI.Material.Controls;


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
            AudioCodecEncoderPicker.ItemsSource = AdbCmdService.selectedDevice.AudioCodecEncoderPairs;
            
        }

        private void OnAudioCodecChanged(object sender, PropertyChangedEventArgs e)
        {            
            audioSettings.AudioCodecEncoderPair = AudioCodecEncoderPicker.SelectedItem?.ToString() ?? "";
            OnAudioSettings_Changed();
        }


        public void SubscribeToEvents()
        {
            AudioCodecEncoderPicker.PropertyChanged += OnAudioCodecChanged;
        }

        public void UnsubscribeToEvents()
        {
            AudioCodecEncoderPicker.PropertyChanged -= OnAudioCodecChanged;
        }


        private void LoadAudioOptions()
        {
            AudioBitRateEntry.Text = audioSettings.AudioBitRate;
            AudioBufferEntry.Text = audioSettings.AudioBuffer;
            AudioDupCheckBox.IsChecked = audioSettings.AudioDup;
            AudioCodecEncoderPicker.SelectedItem = audioSettings.AudioCodecEncoderPair;
            AudioCodecOptionsEntry.Text = audioSettings.AudioCodecOptions;
            NoAudioCheckBox.IsChecked = audioSettings.NoAudio;
        }

        private void OnAudioBitRateChanged(object sender, TextChangedEventArgs e)
        {
            audioSettings.AudioBitRate = e.NewTextValue;
            OnAudioSettings_Changed();
        }

        private void OnAudioBufferChanged(object sender, TextChangedEventArgs e)
        {
            audioSettings.AudioBuffer = e.NewTextValue;
            OnAudioSettings_Changed();
        }

        #region CheckBoxes
        private void OnAudioDupChanged(object sender, EventArgs e)
        {
            var checkBox = sender as InputKit.Shared.Controls.CheckBox;
            audioSettings.AudioDup = checkBox?.IsChecked ?? false;
            OnAudioSettings_Changed();
        }
        
        private void OnNoAudioChanged(object sender, EventArgs e)
        {
            var checkBox = sender as InputKit.Shared.Controls.CheckBox;
            audioSettings.NoAudio = checkBox?.IsChecked ?? false;
            OnAudioSettings_Changed();
        }
        #endregion

        private void OnAudioCodecChanged(object sender, EventArgs e)
        {
            if (AudioCodecEncoderPicker.SelectedItem is string selectedCodec)
            {
                audioSettings.AudioCodecEncoderPair = selectedCodec;
                OnAudioSettings_Changed();
            }
        }

        private void OnAudioCodecOptionsChanged(object sender, TextChangedEventArgs e)
        {
            audioSettings.AudioCodecOptions = e.NewTextValue;
            OnAudioSettings_Changed();
        }

        private void OnAudioSettings_Changed()
        {
            AudioSettingsChanged?.Invoke(this, audioSettings.GenerateCommandPart());
        }


        public void CleanSettings(object sender, EventArgs e)
        {
            AudioSettingsChanged?.Invoke(this, "");
            audioSettings = new AudioOptions();
            ResetAllControls();
        }


        //Sets the values for Codecs-Encoders from the current selected device
        public void ReloadCodecsEncoders()
        {
            AudioCodecEncoderPicker.ItemsSource = AdbCmdService.selectedDevice.VideoCodecEncoderPairs;
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
            AudioCodecEncoderPicker.SelectedIndex = -1;
            audioSettings.AudioCodecEncoderPair = "";
        }
    }
}
