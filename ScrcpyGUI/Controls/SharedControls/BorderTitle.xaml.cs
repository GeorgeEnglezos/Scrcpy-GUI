using Microsoft.Maui.Controls;
using System.Diagnostics;

namespace ScrcpyGUI.Controls;

public partial class BorderTitle : ContentView
{
    public BorderTitle()
    {
        InitializeComponent();
    }

    // TitleGlyph Property
    public static readonly BindableProperty TitleGlyphProperty = BindableProperty.Create(
        nameof(TitleGlyph),
        typeof(string),
        typeof(BorderTitle),
        "");

    public string TitleGlyph
    {
        get => (string)GetValue(TitleGlyphProperty);
        set => SetValue(TitleGlyphProperty, value);
    }

    // TitleText Property
    public static readonly BindableProperty TitleTextProperty = BindableProperty.Create(
        nameof(TitleText),
        typeof(string),
        typeof(BorderTitle),
        "Title");

    public string TitleText
    {
        get => (string)GetValue(TitleTextProperty);
        set => SetValue(TitleTextProperty, value);
    }

    // ShowButton Property
    public static readonly BindableProperty ShowButtonProperty = BindableProperty.Create(
        nameof(ShowButton),
        typeof(bool),
        typeof(BorderTitle),
        false);

    public bool ShowButton
    {
        get => (bool)GetValue(ShowButtonProperty);
        set => SetValue(ShowButtonProperty, value);
    }

    // ButtonClicked Event
    public event EventHandler ButtonClicked;

    private void OnButtonClicked(object sender, EventArgs e)
    {
        ButtonClicked?.Invoke(this, e);
    }
}