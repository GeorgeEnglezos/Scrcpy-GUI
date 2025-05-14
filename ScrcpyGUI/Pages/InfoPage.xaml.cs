using Microsoft.Maui.Layouts;
using ScrcpyGUI.Models;
using System.Collections.ObjectModel;
using System.Diagnostics;
using static System.Net.Mime.MediaTypeNames;

namespace ScrcpyGUI
{
    public partial class InfoPage : ContentPage
    {
        const string scrcpy_gui_url = "https://github.com/GeorgeEnglezos/Scrcpy-GUI";
        const string scrcpy_official = "https://github.com/Genymobile/scrcpy";
        const string scrcpy_official_docs = "https://github.com/Genymobile/scrcpy/tree/master/doc";


        public InfoPage()
        {
            InitializeComponent();
        }
        // In your .xaml.cs file (code-behind)
        private async void OpenScrcpyGui(object sender, EventArgs e)
        {
            await Launcher.OpenAsync(scrcpy_gui_url);
        }

        private async void OpenScrcpyOfficial(object sender, EventArgs e)
        {
            await Launcher.OpenAsync(scrcpy_official);
        }

        private async void OpenScrcpyOfficialDocs(object sender, EventArgs e)
        {
            await Launcher.OpenAsync(scrcpy_official_docs);
        }

        private async void OnCopyCommand(object sender, EventArgs e)
        {
            await Clipboard.SetTextAsync("dotnet --info");
            await DisplayAlert("Copied", "Command copied to clipboard", "OK");
        }
    }
}
