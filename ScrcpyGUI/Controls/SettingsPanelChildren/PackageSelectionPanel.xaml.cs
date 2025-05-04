using System.Data;
using System.Diagnostics;
using System.Threading.Tasks;

namespace ScrcpyGUI.Controls
{
    public partial class OptionsPackageSelectionPanel : ContentView
    {
        public event EventHandler<string> PackageSelected;
        public List<string> installedPackageList { get; set; } = new List<string>(); // Initialize packageList
        public List<string> allPackageList { get; set; } = new List<string>(); // Initialize packageList

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
            var allPackagesResult = await AdbCmdService.RunAdbCommandAsync(AdbCmdService.CommandEnum.GetPackages, AdbCmdService.allPackagesCommand);
            var installedPackagesResult = await AdbCmdService.RunAdbCommandAsync(AdbCmdService.CommandEnum.GetPackages, AdbCmdService.installedPackagesCommand);
            bool installedPackagesFound = installedPackagesResult.Output != null && installedPackagesResult.Output.Length > 0 && !installedPackagesResult.Output.Contains("no devices/emulators found");
            bool allPackagesFound = allPackagesResult.Output != null && allPackagesResult.Output.Length > 0 && !allPackagesResult.Output.Contains("no devices/emulators found");
            
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

        private void SystemAppsCheckbox_CheckedChanged(object sender, CheckedChangedEventArgs e)
        {
            // Simulate TextChanged event
            var text = PackageSearchEntry.Text;
            PackageSearchEntry_TextChanged(PackageSearchEntry, new TextChangedEventArgs(text, text));
        }

        private void PackageSearchEntry_TextChanged(object sender, TextChangedEventArgs e)
        {
            string searchText = e.NewTextValue?.ToLower();

            if (string.IsNullOrEmpty(searchText) || settingSelectedPackage == searchText)
                for (int i = 0; i < 5; i++)
                {
                    PackageSuggestionsCollectionView.IsVisible = false;
                    return;
                }


            List<string> suggestions;

            if (SystemAppsCheckbox.IsChecked == true) { suggestions = AllPackageList.Where(p => p.ToLower().Contains(searchText)).ToList(); }
            else {suggestions = InstalledPackageList.Where(p => p.ToLower().Contains(searchText)).ToList();} 

            if (suggestions.Count > 0)
            {
                PackageSuggestionsCollectionView.ItemsSource = suggestions;
                PackageSuggestionsCollectionView.IsVisible = true;
            }
            else
            {
                PackageSuggestionsCollectionView.ItemsSource = null;
                PackageSuggestionsCollectionView.IsVisible = false;
            }
        }

        private void PackageSuggestionsCollectionView_SelectionChanged(object sender, SelectionChangedEventArgs e)
        {
            if (e.CurrentSelection != null && e.CurrentSelection.Count > 0)
            {
                string selectedPackage = e.CurrentSelection[0]?.ToString() ?? string.Empty;
                SettingSelectedPackage = selectedPackage;

                // Trigger the event
                PackageSelected?.Invoke(this, selectedPackage);
            }
        }

        public void CleanPackageSelection(object sender, EventArgs e)
        {
            // Reset the Entry
            PackageSearchEntry.Text = string.Empty;

            // Reset the CollectionView
            PackageSuggestionsCollectionView.ItemsSource = null;
            PackageSuggestionsCollectionView.SelectedItem = null; // Clear the selected item
            PackageSuggestionsCollectionView.IsVisible = false;
            PackageSelected?.Invoke(this, "");
        }
        public void RefreshPackages(object sender, EventArgs e) {
            LoadPackages();
        }
    }
}