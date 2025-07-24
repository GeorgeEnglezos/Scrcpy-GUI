using ScrcpyGUI.Models;
using System.ComponentModel;
using System.Diagnostics;
using System.Runtime.CompilerServices;

namespace ScrcpyGUI.Controls;

public partial class OutputPanel : ContentView
{
    private string command = "";
    public event EventHandler<string>? PageRefreshed;
    const string baseScrcpyCommand = "scrcpy.exe --pause-on-exit=if-error";
    private Page parentPage;
    Dictionary<string, Color> completeColorMappings = new Dictionary<string, Color>
    {
        //General
        { "--fullscreen", (Color)Application.Current.Resources["General"] },
        { "--turn-screen-off", (Color)Application.Current.Resources["General"] },
        { "--crop=", (Color)Application.Current.Resources["General"] },
        { "--capture-orientation=", (Color)Application.Current.Resources["General"] },
        { "--stay-awake", (Color)Application.Current.Resources["General"] },
        { "--window-title=", (Color)Application.Current.Resources["General"] },
        { "--video-bit-rate=", (Color)Application.Current.Resources["General"] },
        { "--window-borderless", (Color)Application.Current.Resources["General"] },
        { "--always-on-top", (Color)Application.Current.Resources["General"] },
        { "--disable-screensaver", (Color)Application.Current.Resources["General"] },
        { "--video-codec=", (Color)Application.Current.Resources["General"] },
        { "--video-encoder=", (Color)Application.Current.Resources["General"] },

        //Audio
        { "--audio-bit-rate=", (Color)Application.Current.Resources["Audio"] },
        { "--audio-buffer=", (Color)Application.Current.Resources["Audio"] },
        { "--audio-codec-options=", (Color)Application.Current.Resources["Audio"] },
        { "--audio-codec=", (Color)Application.Current.Resources["Audio"] },
        { "--audio-encoder=", (Color)Application.Current.Resources["Audio"] },
        { "--audio-dup", (Color)Application.Current.Resources["Audio"] },
        { "--no-audio", (Color)Application.Current.Resources["Audio"] },

        //Virtual Display
        { "--new-display", (Color)Application.Current.Resources["VirtualDisplay"] },
        { "--no-vd-destroy-content", (Color)Application.Current.Resources["VirtualDisplay"] },
        { "--no-vd-system-decorations", (Color)Application.Current.Resources["VirtualDisplay"] },

        //Recording
        { "--max-size=", (Color)Application.Current.Resources["Recording"] },
        //{ "--video-bit-rate=", (Color)Application.Current.Resources["Recording"] },
        { "--max-fps=", (Color)Application.Current.Resources["Recording"] },
        { "--record-format=", (Color)Application.Current.Resources["Recording"] },
        { "--record=", (Color)Application.Current.Resources["Recording"] },

        //Package
        { "--start-app", (Color)Application.Current.Resources["PackageSelector"] },
    };
    Dictionary<string, Color> partialColorMappings = new Dictionary<string, Color>
    {
        //General
        { "--fullscreen", (Color)Application.Current.Resources["General"] },
        { "--turn-screen-off", (Color)Application.Current.Resources["General"] },
        { "--video-bit-rate=", (Color)Application.Current.Resources["General"] },

        //Audio
        { "--audio-bit-rate=", (Color)Application.Current.Resources["Audio"] },
        { "--audio-buffer=", (Color)Application.Current.Resources["Audio"] },
        { "--no-audio", (Color)Application.Current.Resources["Audio"] },

        //Virtual Display
        { "--new-display", (Color)Application.Current.Resources["VirtualDisplay"] },

        //Recording
        { "--record-format=", (Color)Application.Current.Resources["Recording"] },
        { "--record=", (Color)Application.Current.Resources["Recording"] },

        //Package
        { "--start-app", (Color)Application.Current.Resources["PackageSelector"] },
    };

    public ScrcpyGuiData jsonData = new ScrcpyGuiData();

    public OutputPanel()
    {
        InitializeComponent();
        BindingContext = this;
        SaveCommand.SetValue(ToolTipProperties.TextProperty, $"Settings and Commands are saved in\n\n{DataStorage.settingsPath}");
        FinalCommandPreview.Text = "Default Command: "+ baseScrcpyCommand;
        command = baseScrcpyCommand;

    }

    public void SubscribeToEvents()
    {
        ChecksPanel.StatusRefreshed += OnRefreshPage;
        jsonData = DataStorage.LoadData();
        OnScrcpyCommandChanged(null, command);

    }

    public void UnsubscribeToEvents()
    {
        ChecksPanel.StatusRefreshed -= OnRefreshPage;
    }

    public void SetOptionsPanelReferenceFromMainPage(OptionsPanel optionsPanel)
    {
        optionsPanel.ScrcpyCommandChanged += OnScrcpyCommandChanged;
    }

    public void Unsubscribe_SetOptionsPanelReferenceFromMainPage(OptionsPanel optionsPanel)
    {
        optionsPanel.ScrcpyCommandChanged += OnScrcpyCommandChanged;
    }

    public void ApplySavedVisibilitySettings()
    {
        var settings = DataStorage.LoadData().AppSettings;

        ChecksPanel.IsVisible = !settings.HideStatusPanel;
        WirelessConnectionPanel.IsVisible = !settings.HideTcpPanel;
        AdbOutputLabelBorder.IsVisible = !settings.HideOutputPanel;

        OnSizeChanged(null, EventArgs.Empty);
    }

    public OutputPanel(OptionsPanel settingsParentPanel) : this()
    {
        SetOptionsPanelReferenceFromMainPage(settingsParentPanel);
    }

    private void OnRefreshPage(object? sender, string e)
    {
        PageRefreshed?.Invoke(this, e);
    }

    protected override void OnBindingContextChanged()
    {
        base.OnBindingContextChanged();
    }


    private async void OnRunGeneratedCommand(object sender, EventArgs e)
    {
        try
        {
            var result = await AdbCmdService.RunScrcpyCommand(command);
            if (!string.IsNullOrEmpty(result.RawError)) {
                await Application.Current.MainPage.DisplayAlert("Error", $"{result.RawError}", "OK");
            }

            AdbOutputLabel.Text = string.IsNullOrEmpty(result.RawError)
                ? $"Output:\n{result.Output}"
                : $"Error:\n{result.RawError}";

            DataStorage.SaveMostRecentCommand(command);
        }
        catch (Exception ex)
        {
            AdbOutputLabel.Text = $"Exception:\n{ex.Message}";
        }
    }


    private async void OnLabelTapped(object sender, TappedEventArgs e)
    {
        try
        {
            string textToCopy = GetFormattedTextSafely();

            if (string.IsNullOrEmpty(textToCopy))
            {
                Console.WriteLine("No text to copy, returning");
                return;
            }

            parentPage = parentPage ?? GetParentPage();
            if (parentPage != null)
            {
                await DataStorage.CopyToClipboardAsync(textToCopy);
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"OnLabelTapped error: {ex.Message}");
            Console.WriteLine($"Stack trace: {ex.StackTrace}");
        }
    }

    private string GetFormattedTextSafely()
    {
        try
        {
            // Try to get text from FormattedString spans
            if (FinalCommandPreview?.FormattedText?.Spans != null && FinalCommandPreview.FormattedText.Spans.Count > 0)
            {
                var allText = string.Join("", FinalCommandPreview.FormattedText.Spans.Select(span => span.Text ?? ""));
                Console.WriteLine($"Got text from spans: '{allText}'");
                return allText;
            }

            // Try to get the Text property directly
            if (!string.IsNullOrEmpty(FinalCommandPreview?.Text))
            {
                Console.WriteLine($"Got text from Text property: '{FinalCommandPreview.Text}'");
                return FinalCommandPreview.Text;
            }

            // Try FormattedText.ToString() as fallback
            if (FinalCommandPreview?.FormattedText != null)
            {
                var formattedText = FinalCommandPreview.FormattedText.ToString();
                Console.WriteLine($"Got text from FormattedText.ToString(): '{formattedText}'");
                return formattedText;
            }

            Console.WriteLine("No text found in any method");
            return "";
        }
        catch (Exception ex)
        {
            Console.WriteLine($"GetFormattedTextSafely error: {ex.Message}");
            return "";
        }
    }

    private ContentPage GetParentPage()
    {
        try
        {
            Element current = this;
            int depth = 0;

            while (current != null && depth < 10)
            {
                if (current is ContentPage page)
                {
                    Console.WriteLine($"Found ContentPage: {page.GetType().Name}");
                    return page;
                }

                current = current.Parent;
                depth++;
            }
            return null;
        }
        catch (Exception ex)
        {
            Console.WriteLine($"GetParentPage error: {ex.Message}");
            return null;
        }
    }

    private void OnSizeChanged(object sender, EventArgs e)
    {
        if (Width < 750 || !ChecksPanel.IsVisible || !WirelessConnectionPanel.IsVisible)
        {
            ResponsiveGrid.RowDefinitions.Clear();
            ResponsiveGrid.ColumnDefinitions.Clear();

            ResponsiveGrid.RowDefinitions.Add(new RowDefinition { Height = GridLength.Star });
            ResponsiveGrid.RowDefinitions.Add(new RowDefinition { Height = GridLength.Star });

            ResponsiveGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Star });

            Grid.SetRow(ChecksPanel, 0);
            Grid.SetColumn(ChecksPanel, 0);

            Grid.SetRow(WirelessConnectionPanel, 1);
            Grid.SetColumn(WirelessConnectionPanel, 0);
        }
        else // Horizontal layout
        {
            ResponsiveGrid.RowDefinitions.Clear();
            ResponsiveGrid.ColumnDefinitions.Clear();

            ResponsiveGrid.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });

            ResponsiveGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Star });
            ResponsiveGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Star });

            Grid.SetRow(ChecksPanel, 0);
            Grid.SetColumn(ChecksPanel, 0);

            Grid.SetRow(WirelessConnectionPanel, 0);
            Grid.SetColumn(WirelessConnectionPanel, 1);
        }
    }


    private void OnSaveGeneratedCommand(object sender, EventArgs e)
    {
        DataStorage.AppendFavoriteCommand(command);
        Application.Current.MainPage.DisplayAlert("Command saved", "View the saved commands in the 'Favorites Page'!", "OK");
    }


    private void OnScrcpyCommandChanged(object? sender, string e)
    {
        command = e;
        if(jsonData.AppSettings.HomeCommandPreviewCommandColors.Equals("None")) FinalCommandPreview.Text = command.ToString();
        else  UpdateCommandPreview(command);
    }


    public void UpdateCommandPreview(string commandText)
    {
        var formattedString = new FormattedString();

        var parts = commandText.Split(' ', StringSplitOptions.RemoveEmptyEntries);
        var colorMappingToUse = jsonData.AppSettings.HomeCommandPreviewCommandColors.Equals("Complete") ? completeColorMappings : partialColorMappings;

            for (int i = 0; i < parts.Length; i++)
            {
            var part = parts[i];
            var span = new Span { Text = part };

            foreach (var mapping in colorMappingToUse)
            {
                if (part.StartsWith(mapping.Key))
                {
                    span.TextColor = mapping.Value;
                    break;
                }
            }

            formattedString.Spans.Add(span);

            // Add space between parts (except for the last one)
            if (i < parts.Length - 1)
            {
                formattedString.Spans.Add(new Span { Text = " " });
            }
        }

        FinalCommandPreview.FormattedText = formattedString;
    }
}
