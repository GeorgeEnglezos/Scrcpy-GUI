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
            this.SizeChanged += OnSizeChanged;
            //AudioCodecEncoderPicker.ItemsSource = AdbCmdService.selectedDevice.AudioCodecEncoderPairs;
        }

        private void OnAudioCodecChanged(object sender, PropertyChangedEventArgs e)
        {            
            //audioSettings.AudioCodecEncoderPair = AudioCodecEncoderPicker.SelectedItem?.ToString() ?? "";
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
            AudioDupCheckBox.IsChecked = audioSettings.AudioDup;
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
        private void OnAudioDupChanged(object sender, CheckedChangedEventArgs e)
        {
            audioSettings.AudioDup = e.Value;
            OnAudioSettings_Changed();
        }
        
        private void OnNoAudioChanged(object sender, CheckedChangedEventArgs e)
        {
            audioSettings.NoAudio = e.Value;
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
            AudioCodecEncoderPicker.ItemsSource = AdbCmdService.selectedDevice.AudioCodecEncoderPairs;
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

        private void OnSizeChanged(object sender, EventArgs e)
        {
            double breakpointWidth = 670;

            if (Width < breakpointWidth)
            {
                AudioGrid.RowDefinitions.Clear();
                AudioGrid.ColumnDefinitions.Clear();

                AudioGrid.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
                AudioGrid.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
                AudioGrid.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
                AudioGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Star });
                AudioGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Star });

                //Row 1
                Grid.SetRow(AudioBitRateEntry, 0);
                Grid.SetColumn(AudioBitRateEntry, 0);

                Grid.SetRow(AudioBufferEntry, 0);
                Grid.SetColumn(AudioBufferEntry, 1);

                //Row 2
                Grid.SetRow(AudioCodecEncoderPicker, 1);
                Grid.SetColumn(AudioCodecEncoderPicker, 0);

                Grid.SetRow(AudioCodecOptionsEntry, 1);
                Grid.SetColumn(AudioCodecOptionsEntry, 1);
                
                //Row 2
                Grid.SetRow(NoAudioCheckBox, 2);
                Grid.SetColumn(NoAudioCheckBox, 0);

                Grid.SetRow(AudioDupCheckBox, 2);
                Grid.SetColumn(AudioDupCheckBox, 1);
            }
            else // Horizontal layout (side by side)
            {
                AudioGrid.RowDefinitions.Clear();
                AudioGrid.ColumnDefinitions.Clear();

                AudioGrid.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
                AudioGrid.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
                AudioGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Star });
                AudioGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Star });
                AudioGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Star });

                //Row 1
                Grid.SetRow(AudioBitRateEntry, 0);
                Grid.SetColumn(AudioBitRateEntry, 0);

                Grid.SetRow(AudioBufferEntry, 0);
                Grid.SetColumn(AudioBufferEntry, 1);

                Grid.SetRow(AudioCodecOptionsEntry, 0);
                Grid.SetColumn(AudioCodecOptionsEntry, 2);
                
                //Row 2
                Grid.SetRow(NoAudioCheckBox, 1);
                Grid.SetColumn(NoAudioCheckBox, 0);

                Grid.SetRow(AudioDupCheckBox, 1);
                Grid.SetColumn(AudioDupCheckBox, 1);

                Grid.SetRow(AudioCodecEncoderPicker, 1);
                Grid.SetColumn(AudioCodecEncoderPicker, 2);

            }
        }
    }
}
