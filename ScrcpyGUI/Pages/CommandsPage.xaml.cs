using Microsoft.Maui.Controls;
using Microsoft.Maui.Graphics;
using ScrcpyGUI.Controls;
using ScrcpyGUI.Models;
using System.Collections.ObjectModel;
using System.ComponentModel;
using System.Diagnostics;
using System.Globalization;

namespace ScrcpyGUI
{
    public partial class CommandsPage : ContentPage, INotifyPropertyChanged
    {
        public ObservableCollection<string> SavedCommandsList { get; set; } = new ObservableCollection<string>();
        public static ScrcpyGuiData jsonData = new ScrcpyGuiData();

        private static Dictionary<string, Color> _cachedColorMapping;
        private static bool _colorMappingInitialized = false;

        private string _mostRecentCommandText;
        public string MostRecentCommandText
        {
            get => _mostRecentCommandText;
            set
            {
                _mostRecentCommandText = value;
                OnPropertyChanged();
            }
        }

        public CommandsPage()
        {
            InitializeComponent();
            this.BindingContext = this;
        }

        protected override void OnAppearing()
        {
            base.OnAppearing();
            jsonData = DataStorage.LoadData();
            ReadSavedCommands();
            ReadLastUsedCommand();
        }

        private void ReadLastUsedCommand()
        {
            string recentCommand = jsonData.MostRecentCommand ?? "No recent command found";
            MostRecentCommandText = recentCommand;
            Debug.WriteLine($"Recent Command: {recentCommand}");
        }

        private void ReadSavedCommands()
        {
            SavedCommandsList.Clear();

            if (jsonData.FavoriteCommands != null)
            {
                foreach (var command in jsonData.FavoriteCommands)
                {
                    SavedCommandsList.Add(command);
                }
            }
        }

        private async void OnCommandTapped(object sender, TappedEventArgs e)
        {
            if (sender is VisualElement element && element.BindingContext is string text)
            {
                await Task.Run(() => AdbCmdService.RunScrcpyCommand(text));
            }
        }

        private async void OnRecentCommandTapped(object sender, EventArgs e)
        {
            var command = MostRecentCommandText ?? "";
            if (!string.IsNullOrEmpty(command))
            {
                await Task.Run(() => AdbCmdService.RunScrcpyCommand(command));
            }
        }

        private async void OnCopyMostRecentCommand(object sender, EventArgs e)
        {
            var command = MostRecentCommandText ?? "";
            if (!string.IsNullOrEmpty(command))
            {
                await Clipboard.SetTextAsync(command);
                await DisplayAlert("Copy Command", $"Command copied: {command}", "OK");
            }
        }

        private async void OnCopyCommand(object sender, EventArgs e)
        {
            if (sender is ImageButton button && button.BindingContext is string command)
            {
                await Clipboard.SetTextAsync(command);
                await DisplayAlert("Copy Command", $"Command copied: {command}", "OK");
            }
        }

        private async void OnDeleteCommand(object sender, EventArgs e)
        {
            if (sender is ImageButton button && button.BindingContext is string text)
            {
                var data = DataStorage.LoadData();
                int indexToDelete = data.FavoriteCommands.IndexOf(text);

                if (indexToDelete >= 0)
                {
                    DataStorage.RemoveFavoriteCommandAtIndex(indexToDelete, data);
                    SavedCommandsList.Remove(text);

                    await DisplayAlert("Success", "Command deleted successfully!", "OK");
                }
                else
                {
                    await DisplayAlert("Error", "Item not found!", "OK");
                }
            }
        }

        private async void OnDownloadBat(object sender, EventArgs e)
        {
            if (sender is ImageButton button && button.BindingContext is string text)
            {
                try
                {
                    string baseFileName = "SavedCommand";
                    if (text.Contains("--start-app="))
                        baseFileName = RenameToPackage(text);

                    string desktopPath = string.IsNullOrEmpty(DataStorage.staticSavedData.AppSettings.DownloadPath) ? Environment.GetFolderPath(Environment.SpecialFolder.Desktop) : DataStorage.staticSavedData.AppSettings.DownloadPath;
                    string fullPath = Path.Combine(desktopPath, baseFileName + ".bat");

                    int counter = 1;
                    while (File.Exists(fullPath))
                    {
                        fullPath = Path.Combine(desktopPath, $"{baseFileName} ({counter}).bat");
                        counter++;
                    }

                    // Write the file asynchronously
                    await File.WriteAllTextAsync(fullPath, text);

                    await DisplayAlert("Success", $"Saved as: {Path.GetFileName(fullPath)} in \n{desktopPath}", "OK");
                }
                catch (Exception ex)
                {
                    await DisplayAlert("Error", $"Couldn't save file: {ex.Message}", "OK");
                }
            }
        }

        private static string RenameToPackage(string command)
        {
            string packageName = string.Empty;
            int startIndex = command.IndexOf("--start-app=");

            if (startIndex == -1) return "SavedCommand";

            startIndex += "--start-app=".Length;
            int endIndex = command.IndexOf(" ", startIndex);

            if (endIndex != -1)
            {
                packageName = command.Substring(startIndex, endIndex - startIndex);
            }
            else
            {
                packageName = command.Substring(startIndex);
            }

            return packageName;
        }

        // Simplified color mapping initialization
        private static void InitializeColorMapping()
        {
            if (_colorMappingInitialized) return;

            _cachedColorMapping = ChooseColorMapping();
            _colorMappingInitialized = true;
        }

        private static Dictionary<string, Color> ChooseColorMapping()
        {
            var colorSetting = jsonData.AppSettings?.FavoritesPageCommandColors ?? "Package Only";

            return colorSetting switch
            {
                "None" => new Dictionary<string, Color>(),
                "Important" => GetPartialColorMappings(),
                "Complete" => GetCompleteColorMappings(),
                _ => GetPackageOnlyColorMapping()
            };
        }

        private static Dictionary<string, Color> GetCompleteColorMappings()
        {
            return new Dictionary<string, Color>
            {
                { "--fullscreen", (Color)Microsoft.Maui.Controls.Application.Current.Resources["General"] },
                { "--turn-screen-off", (Color)Microsoft.Maui.Controls.Application.Current.Resources["General"] },
                { "--crop=", (Color)Microsoft.Maui.Controls.Application.Current.Resources["General"] },
                { "--capture-orientation=", (Color)Microsoft.Maui.Controls.Application.Current.Resources["General"] },
                { "--stay-awake", (Color)Microsoft.Maui.Controls.Application.Current.Resources["General"] },
                { "--window-title=", (Color)Microsoft.Maui.Controls.Application.Current.Resources["General"] },
                { "--video-bit-rate=", (Color)Microsoft.Maui.Controls.Application.Current.Resources["General"] },
                { "--window-borderless", (Color)Microsoft.Maui.Controls.Application.Current.Resources["General"] },
                { "--always-on-top", (Color)Microsoft.Maui.Controls.Application.Current.Resources["General"] },
                { "--disable-screensaver", (Color)Microsoft.Maui.Controls.Application.Current.Resources["General"] },
                { "--video-codec=", (Color)Microsoft.Maui.Controls.Application.Current.Resources["General"] },
                { "--video-encoder=", (Color)Microsoft.Maui.Controls.Application.Current.Resources["General"] },
                { "--audio-bit-rate=", (Color)Microsoft.Maui.Controls.Application.Current.Resources["Audio"] },
                { "--audio-buffer=", (Color)Microsoft.Maui.Controls.Application.Current.Resources["Audio"] },
                { "--audio-codec-options=", (Color)Microsoft.Maui.Controls.Application.Current.Resources["Audio"] },
                { "--audio-codec=", (Color)Microsoft.Maui.Controls.Application.Current.Resources["Audio"] },
                { "--audio-encoder=", (Color)Microsoft.Maui.Controls.Application.Current.Resources["Audio"] },
                { "--audio-dup", (Color)Microsoft.Maui.Controls.Application.Current.Resources["Audio"] },
                { "--no-audio", (Color)Microsoft.Maui.Controls.Application.Current.Resources["Audio"] },
                { "--new-display", (Color)Microsoft.Maui.Controls.Application.Current.Resources["VirtualDisplay"] },
                { "--no-vd-destroy-content", (Color)Microsoft.Maui.Controls.Application.Current.Resources["VirtualDisplay"] },
                { "--no-vd-system-decorations", (Color)Microsoft.Maui.Controls.Application.Current.Resources["VirtualDisplay"] },
                { "--max-size=", (Color)Microsoft.Maui.Controls.Application.Current.Resources["Recording"] },
                { "--max-fps=", (Color)Microsoft.Maui.Controls.Application.Current.Resources["Recording"] },
                { "--record-format=", (Color)Microsoft.Maui.Controls.Application.Current.Resources["Recording"] },
                { "--record=", (Color)Microsoft.Maui.Controls.Application.Current.Resources["Recording"] },
                { "--start-app", (Color)Microsoft.Maui.Controls.Application.Current.Resources["PackageSelector"] },
            };
        }

        private static Dictionary<string, Color> GetPartialColorMappings()
        {
            return new Dictionary<string, Color>
            {
                { "--fullscreen", (Color)Microsoft.Maui.Controls.Application.Current.Resources["General"] },
                { "--turn-screen-off", (Color)Microsoft.Maui.Controls.Application.Current.Resources["General"] },
                { "--video-bit-rate=", (Color)Microsoft.Maui.Controls.Application.Current.Resources["General"] },
                { "--audio-bit-rate=", (Color)Microsoft.Maui.Controls.Application.Current.Resources["Audio"] },
                { "--audio-buffer=", (Color)Microsoft.Maui.Controls.Application.Current.Resources["Audio"] },
                { "--no-audio", (Color)Microsoft.Maui.Controls.Application.Current.Resources["Audio"] },
                { "--new-display", (Color)Microsoft.Maui.Controls.Application.Current.Resources["VirtualDisplay"] },
                { "--record-format=", (Color)Microsoft.Maui.Controls.Application.Current.Resources["Recording"] },
                { "--record=", (Color)Microsoft.Maui.Controls.Application.Current.Resources["Recording"] },
                { "--start-app", (Color)Microsoft.Maui.Controls.Application.Current.Resources["PackageSelector"] },
            };
        }

        private static Dictionary<string, Color> GetPackageOnlyColorMapping()
        {
            return new Dictionary<string, Color>
            {
                { "--start-app", (Color)Microsoft.Maui.Controls.Application.Current.Resources["PackageSelector"] },
            };
        }

        // Enhanced CreateColoredCommandText method
        public static FormattedString CreateColoredCommandText(string commandText)
        {
            InitializeColorMapping();

            var formattedString = new FormattedString();
            var parts = commandText.Split(' ', StringSplitOptions.RemoveEmptyEntries);

            for (int i = 0; i < parts.Length; i++)
            {
                var part = parts[i];
                var span = new Span { Text = part };

                // Use cached color mapping
                foreach (var mapping in _cachedColorMapping)
                {
                    if (part.StartsWith(mapping.Key))
                    {
                        span.TextColor = mapping.Value;
                        break;
                    }
                }

                formattedString.Spans.Add(span);

                if (i < parts.Length - 1)
                {
                    formattedString.Spans.Add(new Span { Text = " " });
                }
            }

            return formattedString;
        }

        public event PropertyChangedEventHandler PropertyChanged;

        protected virtual void OnPropertyChanged([System.Runtime.CompilerServices.CallerMemberName] string propertyName = null)
        {
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
        }
    }

    // Enhanced Command Color Converter
    public class CommandColorConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            if (value is not string commandText)
                return new FormattedString();

            // Check if coloring is disabled
            //if (DataStorage.appSettings?.FavoritesPageCommandColors?.Equals("None") == true)
            //    return new FormattedString { Spans = { new Span { Text = commandText } } };

            return CommandsPage.CreateColoredCommandText(commandText);
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            throw new NotImplementedException();
        }
    }
}