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

    // Add a public parameterless constructor
    public OutputPanel()
    {
        InitializeComponent();
        BindingContext = this;
        ChecksPanel.StatusRefreshed += OnRefreshPage;
        FinalCommandPreview.Text = "Default Command: "+ baseScrcpyCommand;
        command = baseScrcpyCommand;
    }

    // Existing constructor with SettingsParentPanel parameter
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


    // Method to set the SettingsParentPanel instance and subscribe to its event
    public void SetOptionsPanelReferenceFromMainPage(OptionsPanel optionsPanel)
    {
        optionsPanel.ScrcpyCommandChanged += OnScrcpyCommandChanged;
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

    private async void OnRunGeneratedCommand(object sender, EventArgs e)
    {
        try
        {
            // Await the async method to get the result
            var result = await AdbCmdService.RunAdbCommandAsync(AdbCmdService.CommandEnum.RunScrcpy, command);

            // Access the response values
            AdbOutputLabel.Text = string.IsNullOrEmpty(result.RawError)
                ? $"Output:\n{result.Output}"
                : $"Error:\n{result.RawError}";

            // Save the most recent command
            DataStorage.SaveMostRecentCommand(command);
        }
        catch (Exception ex)
        {
            // Handle any exception that occurred during the command execution
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
        DataStorage.AppendCommand(command);
        Application.Current.MainPage.DisplayAlert("Command saved", "View the saved commands in the 'Favorites Page'!", "OK");
    }

}
