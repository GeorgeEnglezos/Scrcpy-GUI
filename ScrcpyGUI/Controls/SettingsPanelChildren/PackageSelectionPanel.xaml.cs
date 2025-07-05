using System.Data;
using System.Diagnostics;
using System.Threading.Tasks;
using System.ComponentModel;
using System.Windows.Input;

namespace ScrcpyGUI.Controls
{
    public partial class OptionsPackageSelectionPanel : ContentView, INotifyPropertyChanged
    {
        public event EventHandler<string> PackageSelected;
        public bool IncludeSystemApps = false;

        public List<string> installedPackageList { get; set; } = new List<string>();
        public List<string> allPackageList { get; set; } = new List<string>();


        private string _packageTextColor = "Black";
        public string PackageTextColor
        {
            get => _packageTextColor;
            set { _packageTextColor = value; OnPropertyChanged(); }
        }

        private string settingSelectedPackage = "";
        public string SettingSelectedPackage
        {
            get => settingSelectedPackage;
            set
            {
                if (settingSelectedPackage != value)
                {
                    settingSelectedPackage = value;
                    PackageSearchEntry.Text = value;
                }
            }
        }

        public List<string> InstalledPackageList
        {
            get => installedPackageList;
            set => installedPackageList = value;
        }

        public List<string> AllPackageList
        {
            get => allPackageList;
            set => allPackageList = value;
        }

        public OptionsPackageSelectionPanel()
        {
            InitializeComponent();
            LoadPackages();
            BindingContext = this;
        }

        public async Task LoadPackages()
        {
            if (string.IsNullOrEmpty(AdbCmdService.selectedDevice.DeviceId)) return;

            var allPackagesResult = await AdbCmdService.RunAdbCommandAsync(AdbCmdService.CommandEnum.GetPackages, AdbCmdService.allPackagesCommand);
            var installedPackagesResult = await AdbCmdService.RunAdbCommandAsync(AdbCmdService.CommandEnum.GetPackages, AdbCmdService.installedPackagesCommand);
            bool installedPackagesFound = installedPackagesResult.Output != null && installedPackagesResult.Output.Length > 0 && !installedPackagesResult.Output.Contains("no devices/emulators found") && !installedPackagesResult.Output.Contains("adb.exe:");
            bool allPackagesFound = allPackagesResult.Output != null && allPackagesResult.Output.Length > 0 && !allPackagesResult.Output.Contains("no devices/emulators found") && !allPackagesResult.Output.Contains("adb.exe:");

            if (!installedPackagesFound || !allPackagesFound)
            {
                PackageSearchEntry.IsEnabled = false;
                PackageTextColor = "Grey";
                return;
            }
            else
            {
                PackageSearchEntry.IsEnabled = true;
                PackageTextColor = "#7b63b2";
            }
            installedPackageList = FormatPackageList(installedPackagesResult.Output) ?? new List<string>();
            allPackageList = FormatPackageList(allPackagesResult.Output) ?? new List<string>();
        }

        private List<string> FormatPackageList(string packageResponse)
        {
            if (string.IsNullOrEmpty(packageResponse))
            {
                return new List<string>(); // Return an empty list for null or empty input
            }

            string[] packageEntries = packageResponse.Split(new[] { "package:" }, StringSplitOptions.RemoveEmptyEntries);

            List<string> packageNames = packageEntries
                .Select(entry => entry.Trim()) // Trim whitespace
                .ToList();

            return packageNames;
        }

        private void SystemAppsCheckboxChanged(object sender, EventArgs e)
        {
            var checkBox = sender as InputKit.Shared.Controls.CheckBox;
            IncludeSystemApps = checkBox?.IsChecked ?? false;
            FilterPackageList();
        }

        private void FilterPackageList()
        {
            string searchText = PackageSearchEntry.Text?.ToLower();
            List<string> suggestions;

            if (IncludeSystemApps)
            {
                suggestions = AllPackageList.Where(p => p.ToLower().Contains(searchText ?? "")).ToList();
            }
            else
            {
                suggestions = InstalledPackageList.Where(p => p.ToLower().Contains(searchText ?? "")).ToList();
            }

            PackageSuggestionsCollectionView.ItemsSource = suggestions;
            PackageSuggestionsCollectionView.IsVisible = suggestions.Count > 0;
        }

        private void PackageSearchEntry_TextChanged(object sender, TextChangedEventArgs e)
        {
            string searchText = e.NewTextValue?.ToLower();

            if (string.IsNullOrEmpty(searchText) || settingSelectedPackage == searchText)
            {
                PackageSuggestionsCollectionView.IsVisible = false;
                return;
            }

            FilterPackageList();
        }

        private void PackageSuggestionsCollectionView_SelectionChanged(object sender, SelectionChangedEventArgs e)
        {
            if (e.CurrentSelection != null && e.CurrentSelection.Count > 0)
            {
                string selectedPackage = e.CurrentSelection[0]?.ToString() ?? string.Empty;
                SettingSelectedPackage = selectedPackage;

                PackageSelected?.Invoke(this, selectedPackage);
            }
        }

        public void CleanPackageSelection(object sender, EventArgs e)
        {
            // Reset the Entry
            PackageSearchEntry.Text = string.Empty;

            // Reset the CollectionView
            PackageSuggestionsCollectionView.ItemsSource = null;
            PackageSuggestionsCollectionView.SelectedItem = null;
            PackageSuggestionsCollectionView.IsVisible = false;
            PackageSelected?.Invoke(this, "");
        }
        public void RefreshPackages(object sender, EventArgs e)
        {
            LoadPackages();
        }

        public event PropertyChangedEventHandler PropertyChanged;

        protected virtual void OnPropertyChanged(string propertyName)
        {
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
        }
    }
}