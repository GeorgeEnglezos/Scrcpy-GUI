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

        //Sets the initial values for Codecs-Encoders from the current selected device
        OptionVideoCodecEncoderPicker.ItemsSource = AdbCmdService.selectedDevice.VideoCodecEncoderPairs;
        BindingContext = this;
        this.SizeChanged += OnSizeChanged;

    }

    public void SubscribeToEvents() {
        OptionVideoOrientationPicker.PropertyChanged += OnVideoOrientationChanged;
        OptionVideoCodecEncoderPicker.PropertyChanged += OnVideoCodecEncoderChanged;
    }

    public void UnsubscribeToEvents() {
        OptionVideoOrientationPicker.PropertyChanged -= OnVideoOrientationChanged;
        OptionVideoCodecEncoderPicker.PropertyChanged -= OnVideoCodecEncoderChanged;
    }

    private void OnVideoOrientationChanged(object sender, PropertyChangedEventArgs e)
    {
        generalSettings.VideoOrientation = OptionVideoOrientationPicker.SelectedItem?.ToString() ?? "";
        OnGenericSettings_Changed();
    }
    
    private void OnVideoCodecEncoderChanged(object sender, PropertyChangedEventArgs e)
    {
        generalSettings.VideoCodecEncoderPair = OptionVideoCodecEncoderPicker.SelectedItem?.ToString() ?? "";
        OnGenericSettings_Changed();
    }

    //Checkboxes
    #region checkboxes
    private void OnFullscreenCheckboxChanged(object sender, CheckedChangedEventArgs e)
    {
        generalSettings.Fullscreen = OptionFullscreenCheck.IsChecked;
        OnGenericSettings_Changed();
    }

    private void OnScreenOffCheckboxChanged(object sender, CheckedChangedEventArgs e)
    {
        generalSettings.TurnScreenOff = OptionTurnScreenOffCheck.IsChecked;
        OnGenericSettings_Changed();
    }
    private void OnStayAwakeCheckboxChanged(object sender, CheckedChangedEventArgs e)
    {
        generalSettings.StayAwake = OptionStayAwakeCheck.IsChecked;
        OnGenericSettings_Changed();
    }
    private void OnBorderlessCheckboxChanged(object sender, CheckedChangedEventArgs e)
    {
        
        generalSettings.WindowBorderless = OptionWindowBorderlessCheck.IsChecked;
        OnGenericSettings_Changed();
    }

    private void OnWindowAlwaysOnTopCheckboxChanged(object sender, CheckedChangedEventArgs e)
    {
        
        generalSettings.WindowAlwaysOnTop = OptionWindowAlwaysOnTopCheck.IsChecked;
        OnGenericSettings_Changed();
    }

    private void OnDisableScreensaverCheckboxChanged(object sender, CheckedChangedEventArgs e)
    {
        
        generalSettings.DisableScreensaver = OptionDisableScreensaverCheck.IsChecked;
        OnGenericSettings_Changed();
    }

    #endregion

    private void OnCropEntryTextChanged(object sender, TextChangedEventArgs e)
    {
        generalSettings.Crop = e.NewTextValue;
        OnGenericSettings_Changed();
    }
    

    private void OnVideoBitRateTextChanged(object sender, TextChangedEventArgs e)
    {
        generalSettings.VideoBitRate = e.NewTextValue;
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

        
    //Sets the values for Codecs-Encoders from the current selected device
    public void ReloadCodecsEncoders() {
        OptionVideoCodecEncoderPicker.ItemsSource = AdbCmdService.selectedDevice.VideoCodecEncoderPairs;
    }

    private void ResetAllControls()
    {
        // Reset CheckBoxes
        OptionFullscreenCheck.IsChecked = false;
        OptionTurnScreenOffCheck.IsChecked = false;
        OptionStayAwakeCheck.IsChecked = false;
        OptionWindowBorderlessCheck.IsChecked = false;
        OptionWindowAlwaysOnTopCheck.IsChecked = false;
        OptionDisableScreensaverCheck.IsChecked = false;

        // Reset Entries
        OptionCropEntry.Text = string.Empty;
        OptionWindowTitleEntry.Text = string.Empty;
        OptionExtraParameterEntry.Text = string.Empty;
        OptionVideoBitRate.Text = "";

        // Reset Picker
        OptionVideoOrientationPicker.SelectedIndex = -1;
        generalSettings.VideoOrientation = "";
        OptionVideoCodecEncoderPicker.SelectedIndex = -1;
        generalSettings.VideoCodecEncoderPair = "";
    }

    private void OnSizeChanged(object sender, EventArgs e)
    {
        double breakpointWidth = 670;

        if (Width < breakpointWidth) // Switch to vertical layout (stacked)
        {
            GeneralGrid.RowDefinitions.Clear();
            GeneralGrid.ColumnDefinitions.Clear();

            GeneralGrid.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
            GeneralGrid.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
            GeneralGrid.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
            GeneralGrid.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
            GeneralGrid.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
            GeneralGrid.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
            GeneralGrid.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
            GeneralGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Star });
            GeneralGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Star });

            //Row 1
            Grid.SetRow(OptionWindowTitleEntry, 0);
            Grid.SetColumn(OptionWindowTitleEntry, 0);

            Grid.SetRow(OptionFullscreenCheck, 0);
            Grid.SetColumn(OptionFullscreenCheck, 1);

            //Row 2
            Grid.SetRow(OptionTurnScreenOffCheck, 1);
            Grid.SetColumn(OptionTurnScreenOffCheck, 0);

            Grid.SetRow(OptionStayAwakeCheck, 1);
            Grid.SetColumn(OptionStayAwakeCheck, 1);

            //Row 3
            Grid.SetRow(OptionWindowAlwaysOnTopCheck, 2);
            Grid.SetColumn(OptionWindowAlwaysOnTopCheck, 0);

            Grid.SetRow(OptionWindowBorderlessCheck, 2);
            Grid.SetColumn(OptionWindowBorderlessCheck, 1);

            //Row 4
            Grid.SetRow(OptionCropEntry, 3);
            Grid.SetColumn(OptionCropEntry, 0);

            Grid.SetRow(OptionDisableScreensaverCheck, 3);
            Grid.SetColumn(OptionDisableScreensaverCheck, 1);

            //Row 4
            Grid.SetRow(OptionVideoOrientationPicker, 4);
            Grid.SetColumn(OptionVideoOrientationPicker, 0);

            Grid.SetRow(OptionVideoBitRate, 4);
            Grid.SetColumn(OptionVideoBitRate, 1);

            //Row 4
            Grid.SetRow(OptionVideoCodecEncoderPicker, 5);
            Grid.SetColumn(OptionVideoCodecEncoderPicker, 0);
            Grid.SetColumnSpan(OptionVideoCodecEncoderPicker, 2);

            //Row 5
            Grid.SetRow(OptionExtraParameterEntry, 6);
            Grid.SetColumn(OptionExtraParameterEntry, 0);
            Grid.SetColumnSpan(OptionExtraParameterEntry, 2);
        }
        else // Horizontal layout (side by side)
        {
            GeneralGrid.RowDefinitions.Clear();
            GeneralGrid.ColumnDefinitions.Clear();

            GeneralGrid.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
            GeneralGrid.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
            GeneralGrid.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
            GeneralGrid.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
            GeneralGrid.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
            GeneralGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Star });
            GeneralGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Star });
            GeneralGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Star });

            //Row 1
            Grid.SetRow(OptionWindowTitleEntry, 0);
            Grid.SetColumn(OptionWindowTitleEntry, 0);

            Grid.SetRow(OptionFullscreenCheck, 0);
            Grid.SetColumn(OptionFullscreenCheck, 1);

            Grid.SetRow(OptionTurnScreenOffCheck, 0);
            Grid.SetColumn(OptionTurnScreenOffCheck, 2);

            //Row 2
            Grid.SetRow(OptionStayAwakeCheck, 1);
            Grid.SetColumn(OptionStayAwakeCheck, 0);

            Grid.SetRow(OptionCropEntry, 1);
            Grid.SetColumn(OptionCropEntry, 1);

            Grid.SetRow(OptionVideoOrientationPicker, 1);
            Grid.SetColumn(OptionVideoOrientationPicker, 2);

            //Row 3
            Grid.SetRow(OptionWindowBorderlessCheck, 2);
            Grid.SetColumn(OptionWindowBorderlessCheck, 0);

            Grid.SetRow(OptionWindowAlwaysOnTopCheck, 2);
            Grid.SetColumn(OptionWindowAlwaysOnTopCheck, 1);

            Grid.SetRow(OptionDisableScreensaverCheck, 2);
            Grid.SetColumn(OptionDisableScreensaverCheck, 2);

            //Row 4
            Grid.SetRow(OptionVideoBitRate, 3);
            Grid.SetColumn(OptionVideoBitRate, 0);

            Grid.SetRow(OptionVideoCodecEncoderPicker, 3);
            Grid.SetColumn(OptionVideoCodecEncoderPicker, 1);
            Grid.SetColumnSpan(OptionVideoCodecEncoderPicker, 2);

            //Row 5
            Grid.SetRow(OptionExtraParameterEntry, 4);
            Grid.SetColumn(OptionExtraParameterEntry, 0);
            Grid.SetColumnSpan(OptionExtraParameterEntry, 3);
        }
    }
}