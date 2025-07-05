namespace ScrcpyGUI
{
    public partial class App : Application
    {
        public App()
        {
            InitializeComponent();
            Application.Current.UserAppTheme = AppTheme.Dark;
            
            LoadSettings();
        }

        protected override Window CreateWindow(IActivationState? activationState)
        {
            return new Window(new AppShell());
        }
    
        private async void LoadSettings()
        {
            DataStorage.staticSavedData = DataStorage.LoadData();
            var settings = DataStorage.staticSavedData.AppSettings;

            // Validate and create paths, with fallbacks to Desktop
            var desktopPath = Environment.GetFolderPath(Environment.SpecialFolder.Desktop);

            AdbCmdService.scrcpyPath = DataStorage.ValidateAndCreatePath(settings.ScrcpyPath);
            AdbCmdService.recordingsPath = DataStorage.ValidateAndCreatePath(settings.RecordingPath, desktopPath);
            DataStorage.staticSavedData.AppSettings.DownloadPath = DataStorage.ValidateAndCreatePath(settings.DownloadPath, desktopPath);
        }
    } 
}