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
        ResetAllControls();
        ResolutionContainer.PropertyChanged += OnResolutionSelected;
        BindingContext = virtualDisplaySettings;
    }

    private void OnVirtualDisplaySettings_Changed()
    {
        VirtualDisplaySettingsChanged?.Invoke(this, virtualDisplaySettings.GenerateCommandPart());
    }

    private void OnNewDisplayCheckedChanged(object sender, EventArgs e)
    {
        var checkBox = sender as InputKit.Shared.Controls.CheckBox;
        ResolutionContainer.IsVisible = checkBox?.IsChecked ?? false;
        DpiEntry.IsVisible = checkBox?.IsChecked ?? false;
        virtualDisplaySettings.NewDisplay = checkBox?.IsChecked ?? false;
        OnVirtualDisplaySettings_Changed();
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

    private void OnNoVdDestroyContentCheckedChanged(object sender, EventArgs e)
    {
        var checkBox = sender as InputKit.Shared.Controls.CheckBox;

        virtualDisplaySettings.NoVdDestroyContent = checkBox?.IsChecked ?? false;
        OnVirtualDisplaySettings_Changed();
    }

    private void OnNoVdSystemDecorationsCheckedChanged(object sender, EventArgs e)
    {
        var checkBox = sender as InputKit.Shared.Controls.CheckBox;

        virtualDisplaySettings.NoVdSystemDecorations = checkBox?.IsChecked ?? false;
        OnVirtualDisplaySettings_Changed();
    }

    public void CleanSettings(object sender, EventArgs e)
    {
        VirtualDisplaySettingsChanged?.Invoke(this, "");
        virtualDisplaySettings = new VirtualDisplayOptions();
        ResetAllControls();
    }

    private void ResetAllControls()
    {
        // Reset CheckBoxes
        NewDisplay.IsChecked = false;
        NoVdDestroyContent.IsChecked = false;
        NoVdSystemDecorations.IsChecked = false;

        // Reset Picker
        ResolutionContainer.SelectedIndex = -1;
        virtualDisplaySettings.Resolution = "";

        // Reset Entry
        DpiEntry.Text = string.Empty;

        // Optionally hide resolution container if logic depends on it
        ResolutionContainer.IsVisible = false;
        DpiEntry.IsVisible = false;
    }

}