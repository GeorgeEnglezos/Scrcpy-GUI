using Microsoft.Maui.Layouts;
using ScrcpyGUI.Models;
using System.Collections.ObjectModel;
using System.Diagnostics;
using static System.Net.Mime.MediaTypeNames;

namespace ScrcpyGUI
{
    /// <summary>
    /// Information page displaying links to documentation and project resources.
    /// DEPRECATED: This .NET MAUI application is being replaced by a Flutter version.
    /// Provides quick access to Scrcpy-GUI and official Scrcpy documentation.
    /// </summary>
    public partial class InfoPage : ContentPage
    {
        const string scrcpy_gui_url = "https://github.com/GeorgeEnglezos/Scrcpy-GUI";
        const string scrcpy_gui_official_docs = "https://github.com/GeorgeEnglezos/Scrcpy-GUI/blob/main/Docs";
        const string scrcpy_official = "https://github.com/Genymobile/scrcpy";
        const string scrcpy_official_docs = "https://github.com/Genymobile/scrcpy/tree/master/doc";

        /// <summary>
        /// Initializes a new instance of the InfoPage class.
        /// </summary>
        public InfoPage()
        {
            InitializeComponent();
        }

        /// <summary>
        /// Opens the Scrcpy-GUI GitHub repository in the default browser.
        /// </summary>
        private async void OpenScrcpyGui(object sender, EventArgs e)
        {
            await Launcher.OpenAsync(scrcpy_gui_url);
        }

        /// <summary>
        /// Opens the Scrcpy-GUI documentation in the default browser.
        /// </summary>
        private async void OpenScrcpyGuiDocs(object sender, EventArgs e)
        {
            await Launcher.OpenAsync(scrcpy_gui_official_docs);
        }

        /// <summary>
        /// Opens the official Scrcpy GitHub repository in the default browser.
        /// </summary>
        private async void OpenScrcpyOfficial(object sender, EventArgs e)
        {
            await Launcher.OpenAsync(scrcpy_official);
        }

        /// <summary>
        /// Opens the official Scrcpy documentation in the default browser.
        /// </summary>
        private async void OpenScrcpyOfficialDocs(object sender, EventArgs e)
        {
            await Launcher.OpenAsync(scrcpy_official_docs);
        }

        /// <summary>
        /// Copies the "dotnet --info" command to the clipboard for diagnostic purposes.
        /// Displays a confirmation alert when complete.
        /// </summary>
        private async void OnCopyCommand(object sender, EventArgs e)
        {
            await Clipboard.SetTextAsync("dotnet --info");
            await DisplayAlert("Copied", "Command copied to clipboard", "OK");
        }
    }
}
