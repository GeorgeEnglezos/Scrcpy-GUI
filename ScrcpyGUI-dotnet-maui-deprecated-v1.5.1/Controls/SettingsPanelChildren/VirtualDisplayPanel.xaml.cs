using ScrcpyGUI.Models;
using System.Diagnostics;

namespace ScrcpyGUI.Controls;

public partial class OptionsVirtualDisplayPanel : ContentView
{

    public event EventHandler<string> VirtualDisplaySettingsChanged;
    private VirtualDisplayOptions virtualDisplaySettings = new VirtualDisplayOptions();

    public OptionsVirtualDisplayPanel()
    {
        InitializeComponent();
        this.SizeChanged += OnSizeChanged;
        OnEnableVDChanged(null,null);
        ResetAllControls();
    }

    public void SubscribeToEvents()
    {
        ResolutionContainer.PropertyChanged += OnResolutionSelected;
    }

    public void UnsubscribeToEvents()
    {
        ResolutionContainer.PropertyChanged -= OnResolutionSelected;
    }

    private void OnResolutionSelected(object sender, EventArgs e)
    {
        virtualDisplaySettings.Resolution = ResolutionContainer.SelectedItem?.ToString() ?? "";
        OnVirtualDisplaySettings_Changed();
    }

    private void OnDpiTextChanged(object sender, TextChangedEventArgs e)
    {
        virtualDisplaySettings.Dpi = e.NewTextValue;
        OnVirtualDisplaySettings_Changed();
    }

    private void OnNoVdDestroyContentCheckedChanged(object sender, CheckedChangedEventArgs e)
    {
        virtualDisplaySettings.NoVdDestroyContent = NoVdDestroyContent.IsChecked;
        OnVirtualDisplaySettings_Changed();
    }

    private void OnNoVdSystemDecorationsCheckedChanged(object sender, CheckedChangedEventArgs e)
    {
        virtualDisplaySettings.NoVdSystemDecorations = NoVdSystemDecorations.IsChecked;
        OnVirtualDisplaySettings_Changed();
    }

    private void OnEnableVDChanged(object sender, CheckedChangedEventArgs e)
    {
        bool isEnabled = NewDisplay.IsChecked;
        virtualDisplaySettings.NewDisplay = isEnabled;


        ResolutionContainer.IsEnabled = isEnabled;
        NoVdDestroyContent.IsEnabled = isEnabled;
        NoVdSystemDecorations.IsEnabled = isEnabled;
        DpiEntry.IsEnabled = isEnabled;
        
        if (!isEnabled) CleanSettings(null, null);
        OnVirtualDisplaySettings_Changed();
    }

    public void CleanSettings(object sender, EventArgs e)
    {
        VirtualDisplaySettingsChanged?.Invoke(this, "");
        virtualDisplaySettings = new VirtualDisplayOptions();
        ResetAllControls();
    }

    private void OnVirtualDisplaySettings_Changed()
    {
        VirtualDisplaySettingsChanged?.Invoke(this, virtualDisplaySettings.GenerateCommandPart());
    }

    private void ResetAllControls()
    {
        // Reset CheckBoxes
        NewDisplay.IsChecked = false;
        NoVdDestroyContent.IsChecked = false;
        NoVdSystemDecorations.IsChecked = false;

        // Reset Picker
        ResolutionContainer.SelectedIndex = 0;
        virtualDisplaySettings.Resolution = "";

        // Reset Entry
        DpiEntry.Text = string.Empty;
    }

    private void OnSizeChanged(object sender, EventArgs e)
    {
        double breakpointWidth = 670;

        if (Width < breakpointWidth) // Switch to vertical layout (stacked)
        {
            VirtualDisplayGrid.RowDefinitions.Clear();
            VirtualDisplayGrid.ColumnDefinitions.Clear();

            VirtualDisplayGrid.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
            VirtualDisplayGrid.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
            VirtualDisplayGrid.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
            VirtualDisplayGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Star });
            VirtualDisplayGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Star });

            //Row 1
            Grid.SetRow(NewDisplay, 0);
            Grid.SetColumn(NewDisplay, 0);

            Grid.SetRow(ResolutionContainer, 0);
            Grid.SetColumn(ResolutionContainer, 1);

            //Row 2
            Grid.SetRow(NoVdDestroyContent, 1);
            Grid.SetColumn(NoVdDestroyContent, 0);

            Grid.SetRow(NoVdSystemDecorations, 1);
            Grid.SetColumn(NoVdSystemDecorations, 1);

            //Row 3
            Grid.SetRow(DpiEntry, 2);
            Grid.SetColumn(DpiEntry, 0);
        }
        else // Horizontal layout (side by side)
        {
            VirtualDisplayGrid.RowDefinitions.Clear();
            VirtualDisplayGrid.ColumnDefinitions.Clear();

            VirtualDisplayGrid.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
            VirtualDisplayGrid.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
            VirtualDisplayGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Star });
            VirtualDisplayGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Star });
            VirtualDisplayGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Star });

            //Row 1
            Grid.SetRow(NewDisplay, 0);
            Grid.SetColumn(NewDisplay, 0);

            Grid.SetRow(ResolutionContainer, 0);
            Grid.SetColumn(ResolutionContainer, 1);

            Grid.SetRow(NoVdDestroyContent, 0);
            Grid.SetColumn(NoVdDestroyContent, 2);

            //Row 2
            Grid.SetRow(NoVdSystemDecorations, 1);
            Grid.SetColumn(NoVdSystemDecorations, 0);

            Grid.SetRow(DpiEntry, 1);
            Grid.SetColumn(DpiEntry, 1);
        }
    }
}