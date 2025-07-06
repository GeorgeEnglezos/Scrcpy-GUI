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
        typeof(string), // Assuming TitleGlyph is a string (e.g., a character, icon font code, or SVG path)
        typeof(BorderTitle),
        ""); // Default empty string for TitleGlyph

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

}