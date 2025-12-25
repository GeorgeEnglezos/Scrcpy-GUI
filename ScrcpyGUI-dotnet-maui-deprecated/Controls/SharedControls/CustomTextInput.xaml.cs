using System.Diagnostics;
using ScrcpyGUI.Models;
using System.ComponentModel;
using UraniumUI.Material.Controls;

namespace ScrcpyGUI.Controls;

public partial class CustomTextInput : ContentView
{
    public CustomTextInput()
    {
        InitializeComponent();
    }

    public static readonly BindableProperty LabelTextProperty = BindableProperty.Create(
        nameof(LabelText),
        typeof(string),
        typeof(CustomTextInput),
        string.Empty);

    public string LabelText
    {
        get => (string)GetValue(LabelTextProperty);
        set => SetValue(LabelTextProperty, value);
    }

    public static readonly BindableProperty TooltipTextProperty = BindableProperty.Create(
        nameof(TooltipText),
        typeof(string),
        typeof(CustomTextInput),
        string.Empty);

    public string TooltipText
    {
        get => (string)GetValue(TooltipTextProperty);
        set => SetValue(TooltipTextProperty, value);
    }

    public static readonly BindableProperty TextProperty = BindableProperty.Create(
        nameof(Text),
        typeof(string),
        typeof(CustomTextInput),
        string.Empty,
        BindingMode.TwoWay);

    public string Text
    {
        get => (string)GetValue(TextProperty);
        set => SetValue(TextProperty, value);
    }

    public static readonly BindableProperty UseTooltipProperty = BindableProperty.Create(
        nameof(UseTooltip),
        typeof(bool),
        typeof(CustomTextInput),
        true);

    public bool UseTooltip
    {
        get => (bool)GetValue(UseTooltipProperty);
        set => SetValue(UseTooltipProperty, value);
    }

    public event EventHandler<TextChangedEventArgs> TextChanged;

    private void InputText_Changed(object sender, TextChangedEventArgs e)
    {
        Text = e.NewTextValue;
        TextChanged?.Invoke(this, e);
    }
}