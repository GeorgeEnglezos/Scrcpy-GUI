namespace ScrcpyGUI
{
    /// <summary>
    /// Main application class for the Scrcpy-GUI MAUI application.
    /// DEPRECATED: This .NET MAUI application is being replaced by a Flutter version.
    /// Manages application lifecycle, theming, and initialization.
    /// </summary>
    public partial class App : Application
    {
        /// <summary>
        /// Initializes a new instance of the App class.
        /// Sets up the application shell, applies dark theme, and registers cleanup handlers.
        /// </summary>
        public App()
        {
            InitializeComponent();
            MainPage = new AppShell();
            Application.Current.UserAppTheme = AppTheme.Dark;

            // Set up cleanup for when the app closes
            AppDomain.CurrentDomain.ProcessExit += OnProcessExit;
        }

        /// <summary>
        /// Creates and configures the application window.
        /// </summary>
        /// <param name="activationState">The activation state for the window.</param>
        /// <returns>Configured window with custom title bar.</returns>
        protected override Window CreateWindow(IActivationState activationState)
        {
            var window = base.CreateWindow(activationState);

            SetupDarkTitleBar(window);
            return window;
        }

        /// <summary>
        /// Handles application exit by cleaning up the single-instance mutex.
        /// </summary>
        /// <param name="sender">Event sender.</param>
        /// <param name="e">Event arguments.</param>
        private void OnProcessExit(object? sender, EventArgs e)
        {
            MauiProgram.CleanupMutex();
        }

        /// <summary>
        /// Called when the application starts.
        /// Loads user settings and initializes application state.
        /// </summary>
        protected override void OnStart()
        {
            base.OnStart();
            LoadSettings();
        }

        /// <summary>
        /// Called when the application is put to sleep (minimized/backgrounded).
        /// </summary>
        protected override void OnSleep()
        {
            base.OnSleep();
        }

        /// <summary>
        /// Called when the application is resumed from sleep.
        /// </summary>
        protected override void OnResume()
        {
            base.OnResume();
        }

        /// <summary>
        /// Loads application settings and validates/creates necessary file paths.
        /// Ensures recording and download paths exist with fallbacks to default system folders.
        /// </summary>
        private async void LoadSettings()
        {
            DataStorage.staticSavedData = DataStorage.LoadData();
            var settings = DataStorage.staticSavedData.AppSettings;

            // Validate and create paths, with fallbacks to Desktop
            var desktopPath = Environment.GetFolderPath(Environment.SpecialFolder.Desktop);
            string videosPath = Environment.GetFolderPath(Environment.SpecialFolder.MyVideos);

            AdbCmdService.SetScrcpyPath();

            AdbCmdService.recordingsPath = DataStorage.ValidateAndCreatePath(settings.RecordingPath, videosPath);
            settings.RecordingPath = AdbCmdService.recordingsPath;

            DataStorage.staticSavedData.AppSettings.DownloadPath = DataStorage.ValidateAndCreatePath(settings.DownloadPath, desktopPath);
            settings.DownloadPath = DataStorage.staticSavedData.AppSettings.DownloadPath;

            DataStorage.staticSavedData.AppSettings = settings;
            DataStorage.SaveData(DataStorage.staticSavedData);
        }

        /// <summary>
        /// Configures the window's title bar with dark theme styling.
        /// </summary>
        /// <param name="window">The window to configure.</param>
        private void SetupDarkTitleBar(Window window)
        {
            window.TitleBar = new TitleBar
            {
                Title = "Scrcpy-GUI v1.5.1.1",
                BackgroundColor = Color.FromArgb("1,1,1"),
                ForegroundColor = Colors.White,
                HeightRequest = 32
            };
        }
    }
}