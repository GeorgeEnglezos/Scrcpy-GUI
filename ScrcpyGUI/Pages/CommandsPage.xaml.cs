using Microsoft.Maui.Controls;
using Microsoft.Maui.Graphics;
using Microsoft.Maui.Layouts;
using ScrcpyGUI.Models;
using System.Collections.ObjectModel;
using System.Diagnostics;
using System.Diagnostics.Tracing;
using System.Globalization;
using System.Runtime.CompilerServices;
using static System.Net.Mime.MediaTypeNames;

namespace ScrcpyGUI
{
    public partial class CommandsPage : ContentPage
    {
        public ObservableCollection<string> SavedCommandsList { get; set; } = new ObservableCollection<string>();
        public static ScrcpyGuiData jsonData = new ScrcpyGuiData();

        public static Dictionary<string, Color> completeColorMappings = new Dictionary<string, Color>
        {
            //General
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

            //Audio
            { "--audio-bit-rate=", (Color)Microsoft.Maui.Controls.Application.Current.Resources["Audio"] },
            { "--audio-buffer=", (Color)Microsoft.Maui.Controls.Application.Current.Resources["Audio"] },
            { "--audio-codec-options=", (Color)Microsoft.Maui.Controls.Application.Current.Resources["Audio"] },
            { "--audio-codec=", (Color)Microsoft.Maui.Controls.Application.Current.Resources["Audio"] },
            { "--audio-encoder=", (Color)Microsoft.Maui.Controls.Application.Current.Resources["Audio"] },
            { "--audio-dup", (Color)Microsoft.Maui.Controls.Application.Current.Resources["Audio"] },
            { "--no-audio", (Color)Microsoft.Maui.Controls.Application.Current.Resources["Audio"] },

            //Virtual Display
            { "--new-display", (Color)Microsoft.Maui.Controls.Application.Current.Resources["VirtualDisplay"] },
            { "--no-vd-destroy-content", (Color)Microsoft.Maui.Controls.Application.Current.Resources["VirtualDisplay"] },
            { "--no-vd-system-decorations", (Color)Microsoft.Maui.Controls.Application.Current.Resources["VirtualDisplay"] },

            //Recording
            { "--max-size=", (Color)Microsoft.Maui.Controls.Application.Current.Resources["Recording"] },
            //{ "--video-bit-rate=", (Color)Microsoft.Maui.Controls.Application.Current.Resources["Recording"] },
            { "--max-fps=", (Color)Microsoft.Maui.Controls.Application.Current.Resources["Recording"] },
            { "--record-format=", (Color)Microsoft.Maui.Controls.Application.Current.Resources["Recording"] },
            { "--record=", (Color)Microsoft.Maui.Controls.Application.Current.Resources["Recording"] },

            //Package
            { "--start-app", (Color)Microsoft.Maui.Controls.Application.Current.Resources["PackageSelector"] },
        };
        public static Dictionary<string, Color> partialColorMappings = new Dictionary<string, Color>
        {
            //General
            { "--fullscreen", (Color)Microsoft.Maui.Controls.Application.Current.Resources["General"] },
            { "--turn-screen-off", (Color)Microsoft.Maui.Controls.Application.Current.Resources["General"] },
            { "--video-bit-rate=", (Color)Microsoft.Maui.Controls.Application.Current.Resources["General"] },

            //Audio
            { "--audio-bit-rate=", (Color)Microsoft.Maui.Controls.Application.Current.Resources["Audio"] },
            { "--audio-buffer=", (Color)Microsoft.Maui.Controls.Application.Current.Resources["Audio"] },
            { "--no-audio", (Color)Microsoft.Maui.Controls.Application.Current.Resources["Audio"] },

            //Virtual Display
            { "--new-display", (Color)Microsoft.Maui.Controls.Application.Current.Resources["VirtualDisplay"] },

            //Recording
            { "--record-format=", (Color)Microsoft.Maui.Controls.Application.Current.Resources["Recording"] },
            { "--record=", (Color)Microsoft.Maui.Controls.Application.Current.Resources["Recording"] },

            //Package
            { "--start-app", (Color)Microsoft.Maui.Controls.Application.Current.Resources["PackageSelector"] },
        };
        public static Dictionary<string, Color> packageOnlyColorMapping = new Dictionary<string, Color>
        {
            { "--start-app", (Color)Microsoft.Maui.Controls.Application.Current.Resources["PackageSelector"] },
        };
        public static Dictionary<string, Color> emptyColorMapping = new Dictionary<string, Color>
        {};

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
            MostRecentCommand.FormattedText = CreateColoredCommandText(recentCommand);                                
            Debug.WriteLine($"Recent Command: {recentCommand}");
        }      

        private void ReadSavedCommands()
        {
            if (SavedCommandsList == null)
            {
                SavedCommandsList = new ObservableCollection<string>();
            }
            else
            {
                SavedCommandsList.Clear();
            }

            foreach (var command in jsonData.FavoriteCommands)
            {
                SavedCommandsList.Add(command);
            }

            if (jsonData.FavoriteCommands != null)
            {
                SavedCommandsTitleCount.Text = $"Favorites ({SavedCommandsList.Count.ToString()})";
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
            await AdbCmdService.RunScrcpyCommand(MostRecentCommand.FormattedText?.ToString() ?? "");
        }

        private void OnCopyCommand(object sender, EventArgs e)
        {
            var button = (ImageButton)sender;
            var command = (string)button.BindingContext;

            Clipboard.SetTextAsync(command);
            DisplayAlert("Copy Command", $"Command copied: {command}", "OK");
        }

        private void OnCopyMostRecentCommand(object sender, EventArgs e)
        {
            var command = MostRecentCommand.FormattedText?.ToString() ?? MostRecentCommand.Text;

            Clipboard.SetTextAsync(command);
            DisplayAlert("Copy Command", $"Command copied: {command}", "OK");
        }

        private void OnDeleteCommand(object sender, EventArgs e)
        {
            if (sender is VisualElement element && element.BindingContext is string text)
            {
                // Load the current saved list
                var data = DataStorage.LoadData();

                // Find the index of the item in the list
                int indexToDelete = data.FavoriteCommands.IndexOf(text);

                // If found, delete the item
                if (indexToDelete >= 0)
                {
                    DataStorage.RemoveFavoriteCommandAtIndex(indexToDelete);
                    Navigation.PushAsync(new CommandsPage());
                    SavedCommandsList.Remove(text);
                }
                else
                {
                    DisplayAlert("Error", "Item not found!", "OK");
                }
            }
        }

        private void OnDownloadBat(object sender, EventArgs e)
        {
            if (sender is Button button && button.BindingContext is string commandText)
            {
                try
                {
                    string baseFileName = "SavedCommand";
                    string desktopPath = Environment.GetFolderPath(Environment.SpecialFolder.Desktop);
                    string fullPath = Path.Combine(desktopPath, baseFileName + ".bat");

                    int counter = 1;
                    while (File.Exists(fullPath))
                    {
                        fullPath = Path.Combine(desktopPath, $"{baseFileName} ({counter}).bat");
                        counter++;
                    }

                    // Write the file
                    File.WriteAllText(fullPath, commandText);

                    DisplayAlert("Success", $"Saved as:\n{Path.GetFileName(fullPath)}", "OK");
                }
                catch (Exception ex)
                {
                    DisplayAlert("Error", $"Couldn't save file: {ex.Message}", "OK");
                }
            }
        }

        public static FormattedString CreateColoredCommandText(string commandText)
        {
            var formattedString = new FormattedString();
            Dictionary<string, Color> colors = chooseColorMapping();            

            // Split and process the command text
            var parts = commandText.Split(' ', StringSplitOptions.RemoveEmptyEntries);

            for (int i = 0; i < parts.Length; i++)
            {
                var part = parts[i];
                var span = new Span { Text = part };

                foreach (var mapping in colors)
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

        private static Dictionary<string, Color> chooseColorMapping()
        {

            if (jsonData.AppSettings.FavoritesPageCommandColors.Equals("None")) 
            { 
                return emptyColorMapping; 
            }
            else if (jsonData.AppSettings.FavoritesPageCommandColors.Equals("Important")) 
            {
                return partialColorMappings; 
            }
            else if (jsonData.AppSettings.FavoritesPageCommandColors.Equals("Complete"))
            { 
                return completeColorMappings; 
            }
            else //(jsonData.AppSettings.FavoritesPageCommandColors == null || jsonData.AppSettings.FavoritesPageCommandColors.Equals("Package Only"))
            {
                return packageOnlyColorMapping;
            }
        }
    }

    // Command Color Converter for ListView items
    public class CommandColorConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            if (value is not string commandText)
                return new FormattedString();

            return CommandsPage.CreateColoredCommandText(commandText);
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            throw new NotImplementedException();
        }
    }
}