﻿using Microsoft.Maui.Layouts;
using System.Diagnostics;
using ScrcpyGUI.Controls;
using ScrcpyGUI.Models;
using Microsoft.Maui.Controls;

namespace ScrcpyGUI
{
    public partial class MainPage : ContentPage
    {
        public MainPage()
        {
            InitializeComponent();

            // Explicitly set the SettingsParentPanel for the OutputPanel
            OutputPanel.SetSettingsParentPanel(SettingsParentPanel);

            OutputPanel.PageRefreshed += OnRefreshPage;
        }

        private async void OnRefreshPage(object? sender, string e)
        {
            //await DisplayAlert("Error", e, "OK");
            ReloadPage();
        }

        private void OnSizeChanged(object sender, EventArgs e)
        {
            if (Width < 1000) // Example threshold for switching layout
            {
                // Switch to 1 column, 2 rows
                MainGrid.ColumnDefinitions.Clear();
                MainGrid.RowDefinitions.Clear();
                MainGrid.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
                MainGrid.RowDefinitions.Add(new RowDefinition { Height = GridLength.Star });

                Grid.SetColumn(SettingsParentPanel, 0);
                Grid.SetRow(SettingsParentPanel, 0);

                Grid.SetColumn(OutputPanel, 0);
                Grid.SetRow(OutputPanel, 1); // Assign OutputPanel to the second row
            }
            else
            {
                // Switch to 2 columns, 1 row
                MainGrid.ColumnDefinitions.Clear();
                MainGrid.RowDefinitions.Clear();
                MainGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Star });
                MainGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Star });

                Grid.SetColumn(SettingsParentPanel, 0);
                Grid.SetRow(SettingsParentPanel, 0);

                Grid.SetColumn(OutputPanel, 1);
                Grid.SetRow(OutputPanel, 0); // Assign OutputPanel to the first row
            }
        }

        public async void ReloadPage() {
            await Navigation.PushAsync(new MainPage());
            Navigation.RemovePage(this);
        }
    }
}
