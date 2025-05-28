using System.Diagnostics;
using ScrcpyGUI.Models;
using System.ComponentModel;
using UraniumUI.Material.Controls;

namespace ScrcpyGUI.Controls;
public partial class SettingsPageOptions : ContentView
{
	public SettingsPageOptions()
	{
		InitializeComponent();
    }

    public static readonly BindableProperty LabelTextProperty =
        BindableProperty.Create(nameof(LabelText), typeof(string), typeof(SettingsPageOptions), string.Empty);

    public string LabelText
    {
        get => (string)GetValue(LabelTextProperty);
        set => SetValue(LabelTextProperty, value);
    }

    public static readonly BindableProperty IsCheckedProperty =
        BindableProperty.Create(nameof(IsChecked), typeof(bool), typeof(SettingsPageOptions), false, BindingMode.TwoWay);

    public bool IsChecked
    {
        get => (bool)GetValue(IsCheckedProperty);
        set => SetValue(IsCheckedProperty, value);
    }

    public event EventHandler<CheckedChangedEventArgs> CheckedChanged;

    private void CheckBox_CheckedChanged(object sender, EventArgs e)
    {
        var checkBox = sender as InputKit.Shared.Controls.CheckBox;
        CheckedChanged?.Invoke(this, new CheckedChangedEventArgs(checkBox?.IsChecked ?? false));
    }
}
