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
        ChecksPanel.StatusRefreshed += OnRefreshPage;
        FinalCommandPreview.Text = "Default Command: "+ baseScrcpyCommand;
        command = baseScrcpyCommand;
    }

    public void ApplySavedVisibilitySettings()
    {
        var settings = DataStorage.LoadData().AppSettings;

        // Apply visibility based on saved AppSettings
        ChecksPanel.IsVisible = !settings.HideStatusPanel;
        WirelessConnectionPanel.IsVisible = !settings.HideTcpPanel;
        AdbOutputLabelBorder.IsVisible = !settings.HideOutputPanel;
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

    public void SetOptionsPanelReferenceFromMainPage(OptionsPanel optionsPanel)
    {
        optionsPanel.ScrcpyCommandChanged += OnScrcpyCommandChanged;
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

    private void OnSaveGeneratedCommand(object sender, EventArgs e)
    {
        // Append the new command to the existing data
        DataStorage.AppendFavoriteCommand(command);
        Application.Current.MainPage.DisplayAlert("Command saved", "View the saved commands in the 'Favorites Page'!", "OK");
    }
}
