using System.Diagnostics;
using Microsoft.Maui.Controls;

namespace ScrcpyGUI.Controls;

public partial class FolderSelector : ContentView
{
    public enum FolderSelectorType
    {
        ScrcpyPath,
        AdbPath,
        DownloadPath,
        RecordingPath,
        ReadOnlyPath,
    }

    // Callback property to notify parent when folder changes
    public Action<string, FolderSelectorType> OnFolderSelected { get; set; }

    // Update your FolderTypeProperty declaration to include a property changed callback
    public static readonly BindableProperty FolderTypeProperty =
        BindableProperty.Create(
            nameof(FolderType),
            typeof(FolderSelectorType),
            typeof(FolderSelector),
            FolderSelectorType.ScrcpyPath,
            propertyChanged: OnFolderTypeChanged); // Add this callback

    public FolderSelectorType FolderType
    {
        get => (FolderSelectorType)GetValue(FolderTypeProperty);
        set => SetValue(FolderTypeProperty, value);
    }

    // Add this new method to handle when FolderType changes
    private static void OnFolderTypeChanged(BindableObject bindable, object oldValue, object newValue)
    {
        var control = (FolderSelector)bindable;
        control.SetButtonVisibility();
    }

    // Keep your existing SetButtonVisibility method
    private void SetButtonVisibility()
    {
        PickFolderButton.IsVisible = FolderType != FolderSelectorType.ReadOnlyPath;
    }

    // Bindable property for initial folder value
    public static readonly BindableProperty InitialFolderProperty =
        BindableProperty.Create(
            nameof(InitialFolder),
            typeof(string),
            typeof(FolderSelector),
            string.Empty,
            propertyChanged: OnInitialFolderChanged);

    public string InitialFolder
    {
        get => (string)GetValue(InitialFolderProperty);
        set => SetValue(InitialFolderProperty, value);
    }

    // Bindable property for custom title
    public static readonly BindableProperty TitleProperty =
        BindableProperty.Create(
            nameof(Title),
            typeof(string),
            typeof(FolderSelector),
            string.Empty,
            propertyChanged: OnTitleChanged);

    public string Title
    {
        get => (string)GetValue(TitleProperty);
        set => SetValue(TitleProperty, value);
    }

    public FolderSelector()
    {
        InitializeComponent();
    }

    private static void OnTitleChanged(BindableObject bindable, object oldValue, object newValue)
    {
        var control = (FolderSelector)bindable;
        var title = newValue as string ?? string.Empty;

        if (!string.IsNullOrEmpty(title))
        {
            control.TitleLabel.Text = title;
        }
    }

    private static void OnInitialFolderChanged(BindableObject bindable, object oldValue, object newValue)
    {
        var control = (FolderSelector)bindable;
        var folder = newValue as string ?? string.Empty;

        if (!string.IsNullOrEmpty(folder))
        {
            control.SelectedFolderLabel.Text = folder;
            control.SelectedFolderLabel.TextColor = Colors.White;
        }
        else
        {
            control.SelectedFolderLabel.Text = "No folder selected";
            control.SelectedFolderLabel.TextColor = Color.FromArgb("#CCCCCC");
        }
    }

    private async void OnPickFolderClicked(object sender, EventArgs e)
    {
        try
        {
            string selectedFolder = await PickFolderAsync();
            if (!string.IsNullOrEmpty(selectedFolder))
            {
                InitialFolder = selectedFolder;
                OnFolderSelected?.Invoke(selectedFolder, FolderType);
            }
        }
        catch (Exception ex)
        {
            SelectedFolderLabel.Text = $"Error: {ex.Message}";
            SelectedFolderLabel.TextColor = Colors.Red;
            Debug.WriteLine($"Error picking folder: {ex.Message}");
        }
    }

    private async Task<string> PickFolderAsync()
    {
#if WINDOWS
        var folderPicker = new Windows.Storage.Pickers.FolderPicker();
        folderPicker.SuggestedStartLocation = Windows.Storage.Pickers.PickerLocationId.Desktop;
        folderPicker.FileTypeFilter.Add("*");

        var window = ((MauiWinUIWindow)Application.Current.Windows[0].Handler.PlatformView);
        var hWnd = WinRT.Interop.WindowNative.GetWindowHandle(window);
        WinRT.Interop.InitializeWithWindow.Initialize(folderPicker, hWnd);

        var result = await folderPicker.PickSingleFolderAsync();
        return result?.Path ?? string.Empty;
#else
        Debug.WriteLine("Folder picking is not implemented for this platform.");
        return string.Empty;
#endif
    }
}