using System.Data;
using System.Diagnostics;
using System.Threading.Tasks;

namespace ScrcpyGUI.Controls
{
    public partial class OptionsPackageSelectionPanel : ContentView
    {
        public event EventHandler<string> PackageSelected;
        public List<string> packageList { get; set; } = new List<string>(); // Initialize packageList

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

        public List<string> PackageList
        {
            get => packageList;
            set => packageList = value;
        }

        public OptionsPackageSelectionPanel()
        {
            InitializeComponent();
            LoadPackages();
            BindingContext = this;
        }

        public async Task LoadPackages()
        {
            var result = await AdbCmdService.RunAdbCommandAsync(AdbCmdService.CommandEnum.GetPackages, AdbCmdService.installedPackagesCommand);
            string packageListOutput = result.Output;
            if (string.IsNullOrEmpty(packageListOutput) || packageListOutput.Contains("no devices/emulators found"))
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
            packageList = FormatPackageList(packageListOutput) ?? new List<string>();
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

        private void PackageSearchEntry_TextChanged(object sender, TextChangedEventArgs e)
        {
            string searchText = e.NewTextValue?.ToLower();

            if (string.IsNullOrEmpty(searchText) || settingSelectedPackage == searchText)
                for (int i = 0; i < 5; i++)
                {
                    PackageSuggestionsCollectionView.IsVisible = false;
                    return;
                }

            var suggestions = packageList.Where(p => p.ToLower().Contains(searchText)).ToList();

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