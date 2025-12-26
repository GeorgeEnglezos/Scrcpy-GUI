using ScrcpyGUI.Models;

namespace ScrcpyGUI.Controls;

public partial class OptionsScreenRecordingPanel : ContentView
{

    public event EventHandler<string> ScreenRecordingOptionsChanged;

    private ScreenRecordingOptions screenRecordingOptions = new ScreenRecordingOptions();
    
    public OptionsScreenRecordingPanel()
    {
        InitializeComponent();
        this.SizeChanged += OnSizeChanged;
        CleanSettings(null,null);
        OnEnableRecordingChanged(null, null);
    }

    public void SubscribeToEvents()
    {
        OutputFormatPicker.PropertyChanged += OnOutputFormatChanged;        
    }

    public void UnsubscribeToEvents()
    {
        OutputFormatPicker.PropertyChanged -= OnOutputFormatChanged;
    }

    private void InitializeRecordingOptions()
    {
        DateTime now = DateTime.Now;
        string formattedDateTime = now.ToString("yyyy_MM_dd_HH_mm_ss");
        FileNameEntry.Text = $"Scrcpy_{formattedDateTime}";

        screenRecordingOptions.OutputFile = Path.Combine(AdbCmdService.recordingsPath, FileNameEntry.Text);
        ResolutionEntry.Text = "";
        FramerateEntry.Text = "30";
        OutputFormatPicker.SelectedItem = "mp4";
    }
    private void OnEnableRecordingChanged(object sender, CheckedChangedEventArgs e)
    {
        bool isEnabled = EnableCheckbox.IsChecked;
        if (isEnabled) InitializeRecordingOptions(); 
        else CleanSettings(null,null);

        ResolutionEntry.IsEnabled = isEnabled;
        FileNameEntry.IsEnabled = isEnabled;
        FramerateEntry.IsEnabled = isEnabled;
        OutputFormatPicker.IsEnabled = isEnabled;
        //OutputFileEntry.IsEnabled = isEnabled;
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

    private void OnFileNameChanged(object sender, TextChangedEventArgs e)
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
        FileNameEntry.Text = $"";
        screenRecordingOptions.OutputFile = string.Empty;
        ResolutionEntry.Text = string.Empty;
        FramerateEntry.Text = string.Empty;

        // Reset Picker
        screenRecordingOptions.OutputFormat = "";
        OutputFormatPicker.SelectedIndex = -1;
    }

    private void OnSizeChanged(object sender, EventArgs e)
    {
        double breakpointWidth = 670;

        if (Width < breakpointWidth) // Switch to vertical layout (stacked)
        {
            RecordingGrid.RowDefinitions.Clear();
            RecordingGrid.ColumnDefinitions.Clear();

            RecordingGrid.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
            RecordingGrid.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
            RecordingGrid.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
            RecordingGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Star });
            RecordingGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Star });

            //Row 1
            Grid.SetRow(EnableCheckbox, 0);
            Grid.SetColumn(EnableCheckbox, 0);

            Grid.SetRow(FileNameEntry, 0);
            Grid.SetColumn(FileNameEntry, 1);
            
            //Row 2
            Grid.SetRow(OutputFormatPicker, 1);
            Grid.SetColumn(OutputFormatPicker, 0);

            Grid.SetRow(FramerateEntry, 1);
            Grid.SetColumn(FramerateEntry, 1);
            
            //Row 3
            Grid.SetRow(ResolutionEntry, 2);
            Grid.SetColumn(ResolutionEntry, 0);
        }
        else // Horizontal layout (side by side)
        {
            RecordingGrid.RowDefinitions.Clear();
            RecordingGrid.ColumnDefinitions.Clear();

            RecordingGrid.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
            RecordingGrid.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
            RecordingGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Star });
            RecordingGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Star });
            RecordingGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Star });

            //Row 1
            Grid.SetRow(EnableCheckbox, 0);
            Grid.SetColumn(EnableCheckbox, 0);

            Grid.SetRow(FileNameEntry, 0);
            Grid.SetColumn(FileNameEntry, 1);

            Grid.SetRow(OutputFormatPicker, 0);
            Grid.SetColumn(OutputFormatPicker, 2);

            //Row 2
            Grid.SetRow(FramerateEntry, 1);
            Grid.SetColumn(FramerateEntry, 0);

            Grid.SetRow(ResolutionEntry, 1);
            Grid.SetColumn(ResolutionEntry, 1);
        }
    }
}

