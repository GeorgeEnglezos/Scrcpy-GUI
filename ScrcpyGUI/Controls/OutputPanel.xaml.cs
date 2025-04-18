using ScrcpyGUI.Models;
using System.ComponentModel;
using System.Diagnostics;
using System.Runtime.CompilerServices;

namespace ScrcpyGUI.Controls;

public partial class OutputPanel : ContentView
{
    private string command = "";
    public event EventHandler<string>? PageRefreshed;
    private bool multiCastCheck = false;
    const string baseScrcpyCommand = "scrcpy.exe --pause-on-exit=if-error";

    // Add a public parameterless constructor
    public OutputPanel()
    {
        InitializeComponent();
        BindingContext = this;
        ChecksPanel.StatusRefreshed += OnRefreshPage;
        FinalCommandPreview.Text = "Default Command: "+ baseScrcpyCommand;
        command = baseScrcpyCommand;
    }

    private void OnRefreshPage(object? sender, string e)
    {
        PageRefreshed?.Invoke(this, e);
    }

    protected override void OnBindingContextChanged()
    {
        base.OnBindingContextChanged();
    }

    // Existing constructor with SettingsParentPanel parameter
    public OutputPanel(SettingsParentPanel settingsParentPanel) : this()
    {
        SetSettingsParentPanel(settingsParentPanel);
    }

    // Method to set the SettingsParentPanel instance and subscribe to its event
    public void SetSettingsParentPanel(SettingsParentPanel settingsParentPanel)
    {
        Debug.WriteLine($"subscribed");

        settingsParentPanel.ScrcpyCommandChanged += OnScrcpyCommandChanged;
    }

    private void OnScrcpyCommandChanged(object? sender, string e)
    {
        Debug.WriteLine($"Scrcpy command changed: {e}");
        command = e;

        // Update the UI with the new command
        if (FinalCommandPreview != null)
        {
            FinalCommandPreview.Text = e;
        }
    }

    private void OnRunGeneratedCommand(object sender, EventArgs e)
    {
        if (multiCastCheck) AdbCmdService.RunAdbCommandAsync(null, AdbCmdService.CommandEnum.RunScrcpy, command);
        else AdbOutputLabel.Text = AdbCmdService.RunAdbCommand(null, AdbCmdService.CommandEnum.RunScrcpy, command).Output;
        DataStorage.SaveMostRecentCommand(command);
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
        DataStorage.AppendCommand(command);
        Application.Current.MainPage.DisplayAlert("Command saved", "View the saved commands in the 'Commands Page'!", "OK");
    }

    private void OnAllowMultipleCastsChanged(object sender, CheckedChangedEventArgs e)
    {
        multiCastCheck = e.Value;
        if (multiCastCheck) AdbOutputLabel.Text = "When using multiple windows, you can't see the command output here!";
        else AdbOutputLabel.Text = "Command Output";
    }

}
