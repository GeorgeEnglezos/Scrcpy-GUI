using Microsoft.Maui.Layouts;
using ScrcpyGUI.Models;
using System.Collections.ObjectModel;
using System.Diagnostics;
using static System.Net.Mime.MediaTypeNames;

namespace ScrcpyGUI
{
    public partial class SettingsPage : ContentPage
    {

        AppSettings settings = new AppSettings();
        ScrcpyGuiData scrcpyData = new ScrcpyGuiData();
        public SettingsPage()
        {
            InitializeComponent();
            scrcpyData = DataStorage.LoadData();
            settings = scrcpyData.AppSettings;
        }

        private void OnCMDChanged(object sender, CheckedChangedEventArgs e)
        {
            bool isChecked = e.Value;
            settings.OpenCmds = isChecked;
            SaveChanges();
        }        
        
        private void OnWirelessPanelChanged(object sender, CheckedChangedEventArgs e)
        {
            bool isChecked = e.Value;
            settings.ShowTcpPanel = isChecked;
            SaveChanges();
        }        

        private void OnStatusPanelChanged(object sender, CheckedChangedEventArgs e)
        {
            bool isChecked = e.Value;
            settings.ShowStatusPanel = isChecked;
            SaveChanges();
        }

        private void OnHideVirtualDisplayPanelChanged(object sender, CheckedChangedEventArgs e)
        {
            bool isChecked = e.Value;
            settings.HideVirtualMonitorPanel = isChecked;
            SaveChanges();
        }
        private void OnHideRecordingPanelChanged(object sender, CheckedChangedEventArgs e)
        {
            bool isChecked = e.Value;
            settings.HideRecordingPanel = isChecked;
            SaveChanges();
        }
        private void OnHideOutputPanelChanged(object sender, CheckedChangedEventArgs e)
        {
            bool isChecked = e.Value;
            settings.HideOutputPanel = isChecked;
            SaveChanges();
        }

        private void SaveChanges() {
            scrcpyData.AppSettings = settings;
            DataStorage.SaveData(scrcpyData);
        }
    }
}
