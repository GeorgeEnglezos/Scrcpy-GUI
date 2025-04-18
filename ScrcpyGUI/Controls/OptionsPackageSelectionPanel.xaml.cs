using System.Data;
using System.Diagnostics;

namespace ScrcpyGUI.Controls
{
    public partial class OptionsPackageSelectionPanel : ContentView
    {
        public event EventHandler<string> PackageSelected;
        private string settingSelectedPackage = "";
        public List<string> packageList { get; set; } = new List<string>(); // Initialize packageList

        public string SettingSelectedPackage
        {
            get => settingSelectedPackage;
            set
            {
                if (settingSelectedPackage != value)
                {
                    settingSelectedPackage = value;
                    PackageSearchEntry.Text = value;
                    //Debug.WriteLine($"Invoking SettingSelectedPackageChanged with value: {value}");
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
        }

        private void LoadPackages()
        {
            string packageListOutput = AdbCmdService.RunAdbCommand(null, AdbCmdService.CommandEnum.GetPackages, AdbCmdService.installedPackagesCommand).Output;
            if (string.IsNullOrEmpty(packageListOutput))
            {
                return;
            }

            packageList = FormatPackageList(packageListOutput) ?? new List<string>(); // Ensure packageList is not null
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
    }
}
