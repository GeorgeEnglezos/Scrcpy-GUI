﻿using Microsoft.Maui.Layouts;
using ScrcpyGUI.Models;
using System.Collections.ObjectModel;
using System.Diagnostics;
using static System.Net.Mime.MediaTypeNames;

namespace ScrcpyGUI
{
    public partial class CommandsPage : ContentPage
    {
        public ObservableCollection<string> SavedCommandsList { get; set; } = new ObservableCollection<string>();
        public ScrcpyGuiData jsonData = new ScrcpyGuiData();
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
            MostRecentCommand.Text = jsonData.MostRecentCommand ?? "No recent command found";
            Debug.WriteLine($"Recent Command: {MostRecentCommand.Text}");
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
                await Task.Run(() => AdbCmdService.RunAdbCommandAsync(AdbCmdService.CommandEnum.RunScrcpy, text));
            }
        }

        private async void OnRecentCommandTapped(object sender, EventArgs e)
        {
            await AdbCmdService.RunAdbCommandAsync(AdbCmdService.CommandEnum.RunScrcpy, MostRecentCommand.Text);
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
            var command = MostRecentCommand.Text;

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
                    //DisplayAlert("Success", $"Removed: {text}", "OK");
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

                    // Optional: confirmation
                    DisplayAlert("Success", $"Saved as:\n{Path.GetFileName(fullPath)}", "OK");
                }
                catch (Exception ex)
                {
                    DisplayAlert("Error", $"Couldn't save file: {ex.Message}", "OK");
                }
            }
        }


    }
}
