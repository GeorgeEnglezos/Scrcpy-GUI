using ScrcpyGUI.Models;
using System.Diagnostics;

namespace ScrcpyGUI.Controls;

public partial class SettingsParentPanel : ContentView
{
    public event EventHandler<string> ScrcpyCommandChanged;

    const string baseScrcpyCommand = "scrcpy.exe --pause-on-exit=if-error";
    private string settingSelectedPackage = "";
    private string recordingCommandPart;
    private string generalCommandPart;
    private string virtualDisplayCommandPart;
    private string audioCommandPart;

    public SettingsParentPanel()
    {
        InitializeComponent();

        // Subscribe to the PackageSelected event
        OptionsPackageSelectionPanel.PackageSelected += OnPackageSelected;
        OptionsScreenRecordingPanel.ScreenRecordingOptionsChanged += OnScreenRecordingOptionsChanged;
        OptionsGeneralPanel.GeneralOptionsChanged += OnGeneralOptionsChanged;
        OptionsVirtualDisplayPanel.VirtualDisplaySettingsChanged += OnVirtualDisplaySettingsChanged;
        OptionsAudioPanel.AudioSettingsChanged += OnAudioSettingsChanged;



    }

    private void OnAudioSettingsChanged(object? sender, string e)
    {
        audioCommandPart = e;
        UpdateFinalCommand();
    }

    private void OnVirtualDisplaySettingsChanged(object? sender, string e)
    {
        virtualDisplayCommandPart = e;
        UpdateFinalCommand();

    }

    private void OnGeneralOptionsChanged(object? sender, string e)
    {
        generalCommandPart = e;
        UpdateFinalCommand();
    }

    private void OnScreenRecordingOptionsChanged(object? sender, string e)
    {
        recordingCommandPart = e;
        UpdateFinalCommand();
    }

    private void OnPackageSelected(object? sender, string selectedPackage)
    {
        settingSelectedPackage = selectedPackage;
        UpdateFinalCommand();
    }

    private void OnRunGeneratedCommand(object sender, EventArgs e)
    {
        var command = UpdateFinalCommand();
        DataStorage.SaveMostRecentCommand(command);
    }


    private string UpdateFinalCommand()
    {
        string fullCommand = baseScrcpyCommand;

        fullCommand += string.IsNullOrEmpty(settingSelectedPackage) ? "" : $" --start-app={settingSelectedPackage}";
        fullCommand += generalCommandPart;
        fullCommand += audioCommandPart;
        fullCommand += virtualDisplayCommandPart;
        fullCommand += recordingCommandPart;

        // Ensure the event is only invoked if there are subscribers
        ScrcpyCommandChanged?.Invoke(this, fullCommand);
        Debug.WriteLine($"ScrcpyCommandChanged Invoked with {fullCommand}");
        return fullCommand;
    }

}
