using ScrcpyGUI.Models;
using System.Diagnostics;


namespace ScrcpyGUI.Controls;
public partial class FixedHeader : ContentView
{

    public event EventHandler<string>? DeviceChanged;


    public FixedHeader()
    {
        InitializeComponent();
        LoadDevices(true);
        StartDeviceWatcher();
    }

    private List<ConnectedDevice> _lastDevices = new();

    private void StartDeviceWatcher()
    {
        Dispatcher.StartTimer(TimeSpan.FromSeconds(5), () =>
        {
            List<ConnectedDevice> currentDevices = AdbCmdService.GetAdbDevices();

            if (!currentDevices.SequenceEqual(_lastDevices))
            {
                _lastDevices = currentDevices;

                Dispatcher.Dispatch(() =>
                {
                    LoadDevices(false);
                });
            }

            return true;
        });
    }

    private void LoadDevices(bool initial)
    {
        var devices = AdbCmdService.GetAdbDevices();
        DevicePicker.ItemsSource = devices;

        if (devices.Count > 0)
        {
            if (initial) DevicePicker.SelectedIndex = 0;
            if (devices.Count == 1)
            {
                DevicePicker.IsEnabled = false;
                DevicePicker.TextColor = Colors.White;
            }
            else
            {
                DevicePicker.IsEnabled = true;
            }
        }
    }


    private void OnDevicePickerIndexChanged(object sender, EventArgs e)
    {
        if (DevicePicker.SelectedIndex == -1)
            return; // No selection

        // Get the full ConnectedDevice object from SelectedItem
        var selectedDevice = DevicePicker.SelectedItem as ConnectedDevice;
        if (selectedDevice == null)
            return;

        // Now you have the full object with all properties
        string model = selectedDevice.DeviceName;
        string deviceId = selectedDevice.DeviceId;

        AdbCmdService.selectedDevice = selectedDevice;

        //Fire event
        DeviceChanged?.Invoke(this, "");

    }

}