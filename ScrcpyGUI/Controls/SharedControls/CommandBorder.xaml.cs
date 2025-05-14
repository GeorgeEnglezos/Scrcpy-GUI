using System.Diagnostics;


namespace ScrcpyGUI.Controls;
public partial class CommandBorder : ContentView
{
	public CommandBorder()
	{
		InitializeComponent();
	}

    public static readonly BindableProperty CommandTextProperty = BindableProperty.Create(nameof(CommandText), typeof(string), typeof(CommandBorder), string.Empty);
    public static readonly BindableProperty CommandTooltipProperty = BindableProperty.Create(nameof(CommandTooltip), typeof(string), typeof(CommandBorder), string.Empty);

    public string CommandText
    {
        get => (string)GetValue(CommandTextProperty);
        set => SetValue(CommandTextProperty, value);
    }
    public string CommandTooltip
    {
        get => (string)GetValue(CommandTooltipProperty);
        set => SetValue(CommandTooltipProperty, value);
    }

    private async void OnCopyClicked(object sender, EventArgs e)
    {
        await Clipboard.SetTextAsync(CommandText);
        await Application.Current.MainPage.DisplayAlert("Copied", "Command copied to clipboard", "OK");
    }
}