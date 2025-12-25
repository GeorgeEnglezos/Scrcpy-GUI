using ScrcpyGUI.Models;
using System.ComponentModel;
using System.Diagnostics;
using System.Runtime.CompilerServices;

namespace ScrcpyGUI.Controls;

/// <summary>
/// Output panel control displaying command preview, execution controls, and ADB output.
/// DEPRECATED: This .NET MAUI application is being replaced by a Flutter version.
/// Provides syntax-highlighted command preview, run/save buttons, and child panels for
/// status checks and wireless connections.
/// </summary>
public partial class OutputPanel : ContentView
{
    private string command = "";

    /// <summary>
    /// Event raised when the page needs to be refreshed.
    /// </summary>
    public event EventHandler<string>? PageRefreshed;

    const string baseScrcpyCommand = "scrcpy.exe --pause-on-exit=if-error";
    private Page parentPage;

    /// <summary>
    /// Complete color mapping dictionary for full syntax highlighting of all Scrcpy parameters.
    /// </summary>
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

    /// <summary>
    /// Partial color mapping dictionary for highlighting only important/commonly used parameters.
    /// </summary>
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

    /// <summary>
    /// Gets or sets the saved application data instance.
    /// </summary>
    public ScrcpyGuiData jsonData = new ScrcpyGuiData();

    /// <summary>
    /// Initializes a new instance of the OutputPanel class.
    /// Sets up data binding, tooltips, and default command preview.
    /// </summary>
    public OutputPanel()
    {
        InitializeComponent();
        BindingContext = this;
        SaveCommand.SetValue(ToolTipProperties.TextProperty, $"Settings and Commands are saved in\n\n{DataStorage.settingsPath}");
        FinalCommandPreview.Text = "Default Command: "+ baseScrcpyCommand;
        command = baseScrcpyCommand;

    }

    /// <summary>
    /// Subscribes to child panel events and loads saved data.
    /// </summary>
    public void SubscribeToEvents()
    {
        ChecksPanel.StatusRefreshed += OnRefreshPage;
        jsonData = DataStorage.LoadData();
        OnScrcpyCommandChanged(null, command);

    }

    /// <summary>
    /// Unsubscribes from child panel events to prevent memory leaks.
    /// </summary>
    public void UnsubscribeToEvents()
    {
        ChecksPanel.StatusRefreshed -= OnRefreshPage;
    }

    /// <summary>
    /// Establishes event subscription to the OptionsPanel for command changes.
    /// Called from MainPage during initialization.
    /// </summary>
    /// <param name="optionsPanel">The OptionsPanel instance to subscribe to.</param>
    public void SetOptionsPanelReferenceFromMainPage(OptionsPanel optionsPanel)
    {
        optionsPanel.ScrcpyCommandChanged += OnScrcpyCommandChanged;
    }

    /// <summary>
    /// Removes event subscription from the OptionsPanel.
    /// Called from MainPage during cleanup.
    /// </summary>
    /// <param name="optionsPanel">The OptionsPanel instance to unsubscribe from.</param>
    public void Unsubscribe_SetOptionsPanelReferenceFromMainPage(OptionsPanel optionsPanel)
    {
        optionsPanel.ScrcpyCommandChanged += OnScrcpyCommandChanged;
    }

    /// <summary>
    /// Applies saved visibility settings to child panels.
    /// Shows/hides panels based on user preferences and triggers layout adjustment.
    /// </summary>
    public void ApplySavedVisibilitySettings()
    {
        var settings = DataStorage.LoadData().AppSettings;

        ChecksPanel.IsVisible = !settings.HideStatusPanel;
        WirelessConnectionPanel.IsVisible = !settings.HideTcpPanel;
        AdbOutputLabelBorder.IsVisible = !settings.HideOutputPanel;

        OnSizeChanged(null, EventArgs.Empty);
    }

    /// <summary>
    /// Initializes a new instance with a reference to the parent OptionsPanel.
    /// </summary>
    /// <param name="settingsParentPanel">The parent OptionsPanel to link with.</param>
    public OutputPanel(OptionsPanel settingsParentPanel) : this()
    {
        SetOptionsPanelReferenceFromMainPage(settingsParentPanel);
    }

    /// <summary>
    /// Handles page refresh requests from child panels and propagates the event upward.
    /// </summary>
    private void OnRefreshPage(object? sender, string e)
    {
        PageRefreshed?.Invoke(this, e);
    }

    /// <summary>
    /// Called when the binding context changes. Currently performs no additional logic.
    /// </summary>
    protected override void OnBindingContextChanged()
    {
        base.OnBindingContextChanged();
    }


    /// <summary>
    /// Handles the Run Command button click event.
    /// Executes the current Scrcpy command, displays errors if any, and saves the command to history.
    /// </summary>
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


    /// <summary>
    /// Handles tap events on the command preview label to copy the command to clipboard.
    /// Extracts formatted text from spans and copies to system clipboard.
    /// </summary>
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

    /// <summary>
    /// Safely extracts text from the formatted command preview label.
    /// Tries multiple methods to retrieve text content from FormattedString spans.
    /// </summary>
    /// <returns>The extracted text, or empty string if extraction fails.</returns>
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

    /// <summary>
    /// Traverses the visual tree to find the parent ContentPage.
    /// Used for displaying alert dialogs from the control.
    /// </summary>
    /// <returns>The parent ContentPage if found, otherwise null.</returns>
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

    /// <summary>
    /// Handles window size changes to implement responsive layout.
    /// Switches between vertical and horizontal layouts for child panels based on width and visibility.
    /// </summary>
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


    /// <summary>
    /// Handles the Save Command button click event.
    /// Adds the current command to the favorites list and displays confirmation.
    /// </summary>
    private void OnSaveGeneratedCommand(object sender, EventArgs e)
    {
        DataStorage.AppendFavoriteCommand(command);
        Application.Current.MainPage.DisplayAlert("Command saved", "View the saved commands in the 'Favorites Page'!", "OK");
    }


    /// <summary>
    /// Handles command changes from the OptionsPanel.
    /// Updates the command preview with or without syntax highlighting based on user settings.
    /// </summary>
    private void OnScrcpyCommandChanged(object? sender, string e)
    {
        command = e;
        if(jsonData.AppSettings.HomeCommandPreviewCommandColors.Equals("None")) FinalCommandPreview.Text = command.ToString();
        else  UpdateCommandPreview(command);
    }


    /// <summary>
    /// Updates the command preview label with syntax-highlighted text.
    /// Applies color spans to command parameters based on user's coloring preference (Complete or Partial).
    /// </summary>
    /// <param name="commandText">The command string to display with syntax highlighting.</param>
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
