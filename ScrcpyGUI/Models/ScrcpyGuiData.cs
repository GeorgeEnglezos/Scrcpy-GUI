using System;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ScrcpyGUI.Models
{
    public class ScrcpyGuiData
    {
        public string MostRecentCommand { get; set; }
        public List<string> FavoriteCommands { get; set; }
        public AppSettings AppSettings { get; set; }

        public ScrcpyGuiData(string mostRecentCommand, List<string> favoriteCommands, AppSettings appSettings)
        {
            MostRecentCommand = mostRecentCommand;
            FavoriteCommands = favoriteCommands ?? new List<string>();
            AppSettings = appSettings ?? new AppSettings();
        }

        public ScrcpyGuiData()
        {
            MostRecentCommand = "";
            FavoriteCommands = new List<string>();
            AppSettings = new AppSettings();
        }
    }

    public class AppSettings() {
        public bool OpenCmds = false;
        public bool HideTcpPanel = false;
        public bool HideStatusPanel = false;
        public bool HideOutputPanel = false;
        public bool HideRecordingPanel = false;
        public bool HideVirtualMonitorPanel = false;
    }

    public class ScreenRecordingOptions
    {

        public string MaxSize { get; set; }
        public string Bitrate { get; set; }
        public string Framerate { get; set; }
        public string OutputFormat { get; set; }
        public string OutputFile { get; set; }

        public ScreenRecordingOptions()
        {
            MaxSize = "";
            Bitrate = "";
            Framerate = "";
            OutputFormat = "";
            OutputFile = "";
        }

        public string GenerateCommandPart()
        {
            try
            {
                string fullCommand = " ";
                fullCommand += !string.IsNullOrEmpty(MaxSize) ? $" --max-size={MaxSize}" : "";
                fullCommand += !string.IsNullOrEmpty(Bitrate) ? $" --video-bit-rate={Bitrate}" : "";
                fullCommand += !string.IsNullOrEmpty(Framerate) ? $" --max-fps={Framerate}" : "";
                fullCommand += !string.IsNullOrEmpty(OutputFormat) ? $" --record-format={OutputFormat}" : "";
                fullCommand += !string.IsNullOrEmpty(OutputFile) ? $" --record={OutputFile}" : "";
                return fullCommand;
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Error in ScreenRecordingOptions.GenerateCommandPart: {ex.Message}");
                throw;
            }
        }
    }  
    
    
    public class VirtualDisplayOptions
    {

        public bool NewDisplay { get; set; }
        public string Resolution { get; set; }
        public bool NoVdDestroyContent { get; set; }
        public bool NoVdSystemDecorations { get; set; }
        public string Dpi { get; set; }

        public VirtualDisplayOptions()
        {
            NewDisplay = false;
            Resolution = "";
            NoVdDestroyContent = false;
            NoVdSystemDecorations = false;
            Dpi = "";
        }

        public string GenerateCommandPart()
        {
            try
            {
                string fullCommand = " ";
                if(NewDisplay)
                {
                    fullCommand += " --new-display";
                    if (!string.IsNullOrEmpty(Resolution))
                    {
                        fullCommand += $"={Resolution}";
                        fullCommand += !string.IsNullOrEmpty(Dpi) ? $"/{Dpi}" : "";
                    }
                    else {
                        fullCommand += !string.IsNullOrEmpty(Dpi) ? $"=/{Dpi}" : "";
                    }
                }
                fullCommand += NoVdDestroyContent ? $" --no-vd-destroy-content" : "";
                fullCommand += NoVdSystemDecorations ? $" --no-vd-system-decorations" : "";
                return fullCommand;
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Error in VirtualDisplayOptions.GenerateCommandPart: {ex.Message}");
                throw;
            }
        }
    }

    public class AudioOptions
    {

        public string AudioBitRate { get; set; } //64000 or 64K
        public string AudioBuffer { get; set; }
        public bool AudioDup { get; set; } // (Android 13+)
        public bool NoAudio{ get; set; }
        public string AudioCodecOptions { get; set; }
        public string AudioCodecEncoderPair { get; set; }

        public AudioOptions()
        {
            AudioBitRate = "";
            AudioBuffer = "";
            AudioDup = false;
            AudioCodecOptions = "";
            AudioCodecEncoderPair = "";
            NoAudio = false;
        }

        public string GenerateCommandPart()
        {
            try
            {
                string fullCommand = " ";
                fullCommand += !string.IsNullOrEmpty(AudioBitRate) ? $" --audio-bit-rate={AudioBitRate}" : "";
                fullCommand += !string.IsNullOrEmpty(AudioBuffer) ? $" --audio-buffer={AudioBuffer}" : "";
                fullCommand += !string.IsNullOrEmpty(AudioCodecEncoderPair) ? $" {AudioCodecEncoderPair}" : "";
                fullCommand += !string.IsNullOrEmpty(AudioCodecOptions) ? $" --audio-codec-options={AudioCodecOptions}" : "";
                fullCommand += AudioDup ? $" --audio-dup" : "";
                fullCommand += NoAudio ? $" --no-audio" : "";
                return fullCommand;
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Error in VirtualDisplayOptions.GenerateCommandPart: {ex.Message}");
                throw;
            }
        }
    }

    public class GeneralCastOptions
    {

        public bool Fullscreen { get; set; }
        public bool TurnScreenOff { get; set; }
        public string WindowTitle { get; set; }
        public string Crop { get; set; }
        public string ExtraParameters { get; set; }
        public string VideoOrientation { get; set; }
        public string VideoCodecEncoderPair { get; set; }
        public bool StayAwake { get; set; }
        public bool WindowBorderless { get; set; }
        public bool WindowAlwaysOnTop { get; set; }
        public bool DisableScreensaver { get; set; }
        public string VideoBitRate { get; set; } //--video-bit-rate
        public GeneralCastOptions()
        {
            Fullscreen = false;
            TurnScreenOff = false;
            WindowTitle = string.Empty;
            Crop = string.Empty;
            VideoOrientation = "";
            VideoCodecEncoderPair = "";
            VideoBitRate = "";
            ExtraParameters = "";
            StayAwake = false;
            WindowBorderless = false;
            WindowAlwaysOnTop = false;
            DisableScreensaver = false;
        }

        public string GenerateCommandPart()
        {
            try
            {
                string fullCommand = " ";
                fullCommand += Fullscreen ? " --fullscreen" : "";
                fullCommand += TurnScreenOff ? " --turn-screen-off" : "";
                fullCommand += !string.IsNullOrEmpty(Crop) ? $" --crop={Crop}" : "";
                fullCommand += !string.IsNullOrEmpty(VideoOrientation) ? $" --capture-orientation={VideoOrientation}" : "";
                fullCommand += StayAwake ? " --stay-awake" : "";
                fullCommand += !string.IsNullOrEmpty(WindowTitle) ? $" --window-title={WindowTitle}" : "";
                fullCommand += !string.IsNullOrEmpty(VideoBitRate) ? $" --video-bit-rate={VideoBitRate}" : "";
                fullCommand += WindowBorderless ? " --window-borderless" : "";
                fullCommand += WindowAlwaysOnTop ? " --always-on-top" : "";
                fullCommand += !string.IsNullOrEmpty(VideoCodecEncoderPair) ? $" {VideoCodecEncoderPair}" : "";
                fullCommand += !string.IsNullOrEmpty(ExtraParameters) ? $" {ExtraParameters}": "";
                //fullCommand += !string.IsNullOrEmpty(WindowPosition) ? $" --window-x={WindowPosition.Split(',')[0]} --window-y={WindowPosition.Split(',')[1]}" : "";
                //fullCommand += !string.IsNullOrEmpty(WindowSize) ? $" --window-width={WindowSize.Split('x')[0]} --window-height={WindowSize.Split('x')[1]}" : "";
                fullCommand += DisableScreensaver ? " --disable-screensaver" : "";
                return fullCommand;
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Error in WindowsCastOptions.GenerateCommandPart: {ex.Message}");
                throw;
            }
        }
    }


    public class ConnectedDevice
    {
        public string CombinedName { get; set; }
        public string DeviceName { get; set; }
        public string DeviceId { get; set; }
        public List<string> AudioCodecEncoderPairs { get; set; }
        public List<string> VideoCodecEncoderPairs { get; set; }
        //public List<string> AudioCodecs { get; set; }
        //public List<string> VideoEncoders { get; set; }
        //public List<string> VideoCodecs { get; set; }

        public ConnectedDevice(){
            CombinedName = "";
            DeviceName = "";
            DeviceId = "";
        }

        public ConnectedDevice(string combinedName, string deviceName, string id)
        {
            this.CombinedName = combinedName;
            this.DeviceName = deviceName;
            this.DeviceId = id;
        }

        public override bool Equals(object obj)
        {
            if (obj is ConnectedDevice other)
            {
                return CombinedName.Equals(other.CombinedName) &&
                        DeviceName.Equals(other.DeviceName) &&
                        DeviceId.Equals(other.DeviceId);
            }
            return false;
        }

        static public bool AreDeviceListsEqual(List<ConnectedDevice> a, List<ConnectedDevice> b)
        {
            var aSet = new HashSet<string>(a.Select(d => d.DeviceId));
            var bSet = new HashSet<string>(b.Select(d => d.DeviceId));
            return aSet.SetEquals(bSet);
        }

        public override int GetHashCode()
        {
            return HashCode.Combine(CombinedName, DeviceName, DeviceId);
        }
    }
}