using System.Diagnostics;
namespace ScrcpyGUI.Controls;

public enum ButtonStyle
{
    CancelButton,
    BasicButton,
    ImageButtonBorder,
    ImageButton,
    TextImageButton
}

public partial class CustomButton : ContentView
{
    public CustomButton()
    {
        InitializeComponent();
        UpdateButtonVisibility();
    }

    // Event that parents can subscribe to
    public event EventHandler<EventArgs> ButtonClicked;

    // ButtonStyle Property
    public static readonly BindableProperty ButtonStyleProperty = BindableProperty.Create(
        nameof(ButtonStyle),
        typeof(ButtonStyle),
        typeof(CustomButton),
        ButtonStyle.BasicButton,
        propertyChanged: OnButtonStyleChanged);

    public ButtonStyle ButtonStyle
    {
        get => (ButtonStyle)GetValue(ButtonStyleProperty);
        set => SetValue(ButtonStyleProperty, value);
    }

    // ButtonText Property
    public static readonly BindableProperty ButtonTextProperty = BindableProperty.Create(
        nameof(ButtonText),
        typeof(string),
        typeof(CustomButton),
        "Button");

    public string ButtonText
    {
        get => (string)GetValue(ButtonTextProperty);
        set => SetValue(ButtonTextProperty, value);
    }

    // ButtonColor Property
    public static readonly BindableProperty ButtonColorProperty = BindableProperty.Create(
        nameof(ButtonColor),
        typeof(Color),
        typeof(CustomButton),
        Colors.Blue);

    public Color ButtonColor
    {
        get => (Color)GetValue(ButtonColorProperty);
        set => SetValue(ButtonColorProperty, value);
    }

    // ButtonStrokeColor Property
    public static readonly BindableProperty ButtonStrokeColorProperty = BindableProperty.Create(
        nameof(ButtonStrokeColor),
        typeof(Color),
        typeof(CustomButton),
        Colors.Blue);

    public Color ButtonStrokeColor
    {
        get => (Color)GetValue(ButtonStrokeColorProperty);
        set => SetValue(ButtonStrokeColorProperty, value);
    }

    // GradientStartColor Property
    public static readonly BindableProperty GradientStartColorProperty = BindableProperty.Create(
        nameof(GradientStartColor),
        typeof(Color),
        typeof(CustomButton),
        Colors.Purple);

    public Color GradientStartColor
    {
        get => (Color)GetValue(GradientStartColorProperty);
        set => SetValue(GradientStartColorProperty, value);
    }

    // GradientEndColor Property
    public static readonly BindableProperty GradientEndColorProperty = BindableProperty.Create(
        nameof(GradientEndColor),
        typeof(Color),
        typeof(CustomButton),
        Colors.Purple);

    public Color GradientEndColor
    {
        get => (Color)GetValue(GradientEndColorProperty);
        set => SetValue(GradientEndColorProperty, value);
    }

    //TextColor Property
    public static readonly BindableProperty TextColorProperty = BindableProperty.Create(
        nameof(TextColor),
        typeof(Color),
        typeof(CustomButton),
        Colors.White);

    public Color TextColor
    {
        get => (Color)GetValue(TextColorProperty);
        set => SetValue(TextColorProperty, value);
    }

    //ShadowColor Property
    public static readonly BindableProperty ShadowColorProperty = BindableProperty.Create(
        nameof(ShadowColor),
        typeof(Color),
        typeof(CustomButton),
        Colors.White);

    public Color ShadowColor
    {
        get => (Color)GetValue(ShadowColorProperty);
        set => SetValue(ShadowColorProperty, value);
    }

    // FontSize Property
    public static readonly BindableProperty FontSizeProperty = BindableProperty.Create(
        nameof(FontSize),
        typeof(double),
        typeof(CustomButton),
        16.0);

    public double FontSize
    {
        get => (double)GetValue(FontSizeProperty);
        set => SetValue(FontSizeProperty, value);
    }

    // FontAttributes Property
    public static readonly BindableProperty FontAttributesProperty = BindableProperty.Create(
        nameof(FontAttributes),
        typeof(FontAttributes),
        typeof(CustomButton),
        FontAttributes.Bold);

    public FontAttributes FontAttributes
    {
        get => (FontAttributes)GetValue(FontAttributesProperty);
        set => SetValue(FontAttributesProperty, value);
    }

    // ButtonHeight Property
    public static readonly BindableProperty ButtonHeightProperty = BindableProperty.Create(
        nameof(ButtonHeight),
        typeof(double),
        typeof(CustomButton),
        null);

    public double ButtonHeight
    {
        get => (double)GetValue(ButtonHeightProperty);
        set => SetValue(ButtonHeightProperty, value);
    }

    // ButtonWidth Property
    public static readonly BindableProperty ButtonWidthProperty = BindableProperty.Create(
        nameof(ButtonWidth),
        typeof(double),
        typeof(CustomButton),
        null);

    public double ButtonWidth
    {
        get => (double)GetValue(ButtonWidthProperty);
        set => SetValue(ButtonWidthProperty, value);
    }

    // ButtonSize Property
    public static readonly BindableProperty ButtonSizeProperty = BindableProperty.Create(
        nameof(ButtonSize),
        typeof(double),
        typeof(CustomButton),
        16.0);

    public double ButtonSize
    {
        get => (double)GetValue(ButtonSizeProperty);
        set => SetValue(ButtonSizeProperty, value);
    }

    // ButtonGlyph Property
    public static readonly BindableProperty ButtonGlyphProperty = BindableProperty.Create(
        nameof(ButtonGlyph),
        typeof(string),
        typeof(CustomButton),
        "");

    public string ButtonGlyph
    {
        get => (string)GetValue(ButtonGlyphProperty);
        set => SetValue(ButtonGlyphProperty, value);
    }

    // TooltipText Property
    public static readonly BindableProperty TooltipTextProperty = BindableProperty.Create(
        nameof(TooltipText),
        typeof(string),
        typeof(CustomButton),
        "");

    public string TooltipText
    {
        get => (string)GetValue(TooltipTextProperty);
        set => SetValue(TooltipTextProperty, value);
    }

    // Property changed handler for ButtonStyle
    private static void OnButtonStyleChanged(BindableObject bindable, object oldValue, object newValue)
    {
        if (bindable is CustomButton customButton)
        {
            customButton.UpdateButtonVisibility();
        }
    }

    // Update button visibility Canceld on style
    private void UpdateButtonVisibility()
    {
        CancelButton.IsVisible = false;
        BasicButton.IsVisible = false;
        TextImageButton.IsVisible = false;
        ImageButton.IsVisible = false;
        ImageButtonBorder.IsVisible = false;

        switch (ButtonStyle)
        {
            case ButtonStyle.CancelButton:
                CancelButton.IsVisible = true;
                break;
            case ButtonStyle.BasicButton:
                BasicButton.IsVisible = true;
                break;
            case ButtonStyle.ImageButton:
                ImageButton.IsVisible = true;
                break;
            case ButtonStyle.ImageButtonBorder:
                ImageButtonBorder.IsVisible = true;
                break;
            case ButtonStyle.TextImageButton:
                TextImageButton.IsVisible = true;
                break;
        }
    }

    private void OnButtonClicked(object sender, EventArgs e)
    {
        ButtonClicked?.Invoke(this, e);
    }
}