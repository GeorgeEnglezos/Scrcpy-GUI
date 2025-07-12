namespace ScrcpyGUI
{
    public partial class App : Application
    {
        public App()
        {
            InitializeComponent();
            MainPage = new AppShell();

            // Set up cleanup for when the app closes
            AppDomain.CurrentDomain.ProcessExit += OnProcessExit;
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

            AdbCmdService.scrcpyPath = DataStorage.ValidateAndCreatePath(settings.ScrcpyPath);

            AdbCmdService.recordingsPath = DataStorage.ValidateAndCreatePath(settings.RecordingPath, videosPath);
            settings.RecordingPath = AdbCmdService.recordingsPath;

            DataStorage.staticSavedData.AppSettings.DownloadPath = DataStorage.ValidateAndCreatePath(settings.DownloadPath, desktopPath);
            settings.DownloadPath = DataStorage.staticSavedData.AppSettings.DownloadPath;

            DataStorage.staticSavedData.AppSettings = settings;
            DataStorage.SaveData(DataStorage.staticSavedData);
        }
    }
}