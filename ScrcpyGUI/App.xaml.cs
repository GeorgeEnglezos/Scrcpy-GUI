namespace ScrcpyGUI
{
    public partial class App : Application
    {
        public App()
        {
            InitializeComponent();
            MainPage = new AppShell();
            Application.Current.UserAppTheme = AppTheme.Dark;

            // Set up cleanup for when the app closes
            AppDomain.CurrentDomain.ProcessExit += OnProcessExit;
        }

        protected override Window CreateWindow(IActivationState activationState)
        {
            var window = base.CreateWindow(activationState);

            SetupDarkTitleBar(window);
            return window;
        }

        private void OnProcessExit(object? sender, EventArgs e)
        {
            MauiProgram.CleanupMutex();
        }

        protected override void OnStart()
        {
            base.OnStart();
            LoadSettings();
        }

        protected override void OnSleep()
        {
            base.OnSleep();
        }

        protected override void OnResume()
        {
            base.OnResume();
        }

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

        private void SetupDarkTitleBar(Window window)
        {
            window.TitleBar = new TitleBar
            {
                Title = "Scrcpy-GUI v1.5.1.1",
                BackgroundColor = Color.FromArgb("1,1,1"), // Dark gray
                ForegroundColor = Colors.White,
                HeightRequest = 32
            };
        }
    }
}