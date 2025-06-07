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

    public OutputPanel()
    {
        InitializeComponent();
        BindingContext = this;
        SaveCommand.SetValue(ToolTipProperties.TextProperty, $"Settings and Commands are saved in\n\n{DataStorage.filePath}");
        FinalCommandPreview.Text = "Default Command: "+ baseScrcpyCommand;
        command = baseScrcpyCommand;

    }

    public void SubscribeToEvents()
    {
        ChecksPanel.StatusRefreshed += OnRefreshPage;
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


    private void OnScrcpyCommandChanged(object? sender, string e)
    {
        command = e;

        if (FinalCommandPreview != null)
        {
            FinalCommandPreview.Text = e;
        }
    }

    private async void OnRunGeneratedCommand(object sender, EventArgs e)
    {
        try
        {
            var result = await AdbCmdService.RunAdbCommandAsync(AdbCmdService.CommandEnum.RunScrcpy, command);
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
        if (AdbOutputLabel != null && !string.IsNullOrEmpty(AdbOutputLabel.Text))
        {
            try
            {
                await Clipboard.SetTextAsync(AdbOutputLabel.Text);
                await Application.Current.MainPage.DisplayAlert("Copied!", "Text copied to clipboard.", "OK");
            }
            catch (FeatureNotSupportedException ex)
            {
                await Application.Current.MainPage.DisplayAlert("Error", "Clipboard functionality not supported.", "OK");
                Console.WriteLine($"Clipboard not supported: {ex.Message}");
            }
            catch (PermissionException ex)
            {
                await Application.Current.MainPage.DisplayAlert("Error", "Clipboard permission denied.", "OK");
                Console.WriteLine($"Clipboard permission denied: {ex.Message}");
            }
            catch (Exception ex)
            {
                await Application.Current.MainPage.DisplayAlert("Error", $"An unexpected error occurred: {ex.Message}", "OK");
                Console.WriteLine($"Clipboard error: {ex.Message}");
            }
        }
    }

    private void OnSizeChanged(object sender, EventArgs e)
    {
        if (Width < 750 || !ChecksPanel.IsVisible || !WirelessConnectionPanel.IsVisible) // Switch to vertical layout
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
}
