using ScrcpyGUI.Models;
using System.Diagnostics;

namespace ScrcpyGUI.Controls;

public partial class OptionsPanel : ContentView
{

    public OptionsPackageSelectionPanel PackageSelector => OptionsPackageSelectionPanel;
    public event EventHandler<string> ScrcpyCommandChanged;
    public event EventHandler PageRefreshed;

    const string baseScrcpyCommand = " --pause-on-exit=if-error";
    private string settingSelectedPackage = "";
    private string recordingCommandPart;
    private string generalCommandPart;
    private string virtualDisplayCommandPart;
    private string audioCommandPart;

    public OptionsPanel()
    {
        InitializeComponent();

        OptionsPackageSelectionPanel.PackageSelected += OnPackageSelected;
        OptionsScreenRecordingPanel.ScreenRecordingOptionsChanged += OnScreenRecordingOptionsChanged;
        OptionsGeneralPanel.GeneralOptionsChanged += OnGeneralOptionsChanged;
        OptionsVirtualDisplayPanel.VirtualDisplaySettingsChanged += OnVirtualDisplaySettingsChanged;
        OptionsAudioPanel.AudioSettingsChanged += OnAudioSettingsChanged;
    }

    public void ApplySavedVisibilitySettings()
    {
        var settings = DataStorage.LoadData().AppSettings;

        OptionsScreenRecordingPanel.IsVisible = !settings.HideRecordingPanel;
        OptionsVirtualDisplayPanel.IsVisible = !settings.HideVirtualMonitorPanel;
    }

    public void SetOutputPanelReferenceFromMainPage(OutputPanel outputpanel)
    {
        outputpanel.PageRefreshed += OnRefreshPage;
    }

    private void OnRefreshPage(object? sender, string e)
    {
        PageRefreshed?.Invoke(this, EventArgs.Empty);
        OptionsPackageSelectionPanel.LoadPackages();
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

        ScrcpyCommandChanged?.Invoke(this, fullCommand);
        Debug.WriteLine($"ScrcpyCommandChanged Invoked with {fullCommand}");
        return fullCommand;
    }

}
