using ScrcpyGUI.Models;
using System.Diagnostics;

namespace ScrcpyGUI.Controls;

public partial class OptionsVirtualDisplayPanel : ContentView
{

    public event EventHandler<string> VirtualDisplaySettingsChanged;
    private VirtualDisplayOptions virtualDisplaySettings = VirtualDisplayOptions.Instance;

    public OptionsVirtualDisplayPanel()
    {
        InitializeComponent();

        // Add event handlers for property changes
        BindingContext = virtualDisplaySettings;
    }

    private void OnVirtualDisplaySettings_Changed()
    {
        VirtualDisplaySettingsChanged?.Invoke(this, virtualDisplaySettings.GenerateCommandPart());
    }

    // Event handler for NewDisplay property
    private void OnNewDisplayCheckedChanged(object sender, CheckedChangedEventArgs e)
    {
        virtualDisplaySettings.NewDisplay = e.Value;
        ResolutionContainer.IsVisible = e.Value; // Toggle visibility of Resolution dropdown
        OnVirtualDisplaySettings_Changed();
    }

    // Event handler for Resolution property
    private void OnResolutionTextChanged(object sender, TextChangedEventArgs e)
    {
        virtualDisplaySettings.Resolution = e.NewTextValue;
        OnVirtualDisplaySettings_Changed();
    }

    // Event handler for Resolution selection
    private void OnResolutionSelected(object sender, EventArgs e)
    {
        if (ResolutionPicker.SelectedItem != null)
        {
            virtualDisplaySettings.Resolution = ResolutionPicker.SelectedItem.ToString();
            OnVirtualDisplaySettings_Changed();
        }
    }

    // Event handler for DPI property
    private void OnDpiTextChanged(object sender, TextChangedEventArgs e)
    {
        // Assuming a DPI property exists in VirtualDisplayOptions
        virtualDisplaySettings.Dpi = e.NewTextValue;
        OnVirtualDisplaySettings_Changed();
    }

    // Event handler for NoVdDestroyContent property
    private void OnNoVdDestroyContentCheckedChanged(object sender, CheckedChangedEventArgs e)
    {
        virtualDisplaySettings.NoVdDestroyContent = e.Value;
        OnVirtualDisplaySettings_Changed();
    }

    // Event handler for NoVdSystemDecorations property
    private void OnNoVdSystemDecorationsCheckedChanged(object sender, CheckedChangedEventArgs e)
    {
        virtualDisplaySettings.NoVdSystemDecorations = e.Value;
        OnVirtualDisplaySettings_Changed();
    }
}