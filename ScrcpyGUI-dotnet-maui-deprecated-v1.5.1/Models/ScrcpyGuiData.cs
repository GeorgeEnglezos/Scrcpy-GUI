using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ScrcpyGUI.Models
{
    /// <summary>
    /// Root data model for the Scrcpy-GUI application settings and user data.
    /// DEPRECATED: This .NET MAUI application is being replaced by a Flutter version.
    /// Stores recent commands, favorites, and application settings.
    /// </summary>
    public class ScrcpyGuiData
    {
        /// <summary>
        /// Gets or sets the most recently executed Scrcpy command.
        /// </summary>
        public string MostRecentCommand { get; set; }

        /// <summary>
        /// Gets or sets the list of user-saved favorite commands.
        /// </summary>
        public List<string> FavoriteCommands { get; set; }

        /// <summary>
        /// Gets or sets the application settings.
        /// </summary>
        public AppSettings AppSettings { get; set; }

        /// <summary>
        /// Initializes a new instance with specified values.
        /// </summary>
        public ScrcpyGuiData(string mostRecentCommand, List<string> favoriteCommands, AppSettings appSettings)
        {
            MostRecentCommand = mostRecentCommand;
            FavoriteCommands = favoriteCommands ?? new List<string>();
            AppSettings = appSettings ?? new AppSettings();
        }

        /// <summary>
        /// Initializes a new instance with default values.
        /// </summary>
        public ScrcpyGuiData()
        {
            MostRecentCommand = "";
            FavoriteCommands = new List<string>();
            AppSettings = new AppSettings();
        }
    }

    /// <summary>
    /// Application-level settings for UI visibility and path configuration.
    /// </summary>
    public class AppSettings()
    {
        /// <summary>
        /// Whether to show command windows when executing commands.
        /// </summary>
        public bool OpenCmds = false;

        /// <summary>
        /// Whether to hide the wireless TCP connection panel.
        /// </summary>
        public bool HideTcpPanel = false;

        /// <summary>
        /// Whether to hide the device status panel.
        /// </summary>
        public bool HideStatusPanel = false;

        /// <summary>
        /// Whether to hide the command output panel.
        /// </summary>
        public bool HideOutputPanel = false;

        /// <summary>
        /// Whether to hide the screen recording options panel.
        /// </summary>
        public bool HideRecordingPanel = false;

        /// <summary>
        /// Whether to hide the virtual display options panel.
        /// </summary>
        public bool HideVirtualMonitorPanel = false;

        /// <summary>
        /// Color scheme for command preview on home page ("None", "Important", "Complete").
        /// </summary>
        public string HomeCommandPreviewCommandColors = "None";

        /// <summary>
        /// Color scheme for commands on favorites page ("None", "Package Only", "Important", "Complete").
        /// </summary>
        public string FavoritesPageCommandColors = "Package Only";

        /// <summary>
        /// Path to the Scrcpy executable folder.
        /// </summary>
        public string ScrcpyPath = "";

        /// <summary>
        /// Path where screen recordings are saved.
        /// </summary>
        public string RecordingPath = "";

        /// <summary>
        /// Path where downloaded batch files are saved.
        /// </summary>
        public string DownloadPath = "";
    }

    /// <summary>
    /// Configuration options for screen recording functionality.
    /// Generates Scrcpy command-line parameters for recording settings.
    /// </summary>
    public class ScreenRecordingOptions
    {
        /// <summary>
        /// Maximum video dimension (e.g., "1920").
        /// </summary>
        public string MaxSize { get; set; }

        /// <summary>
        /// Video bitrate (e.g., "8M").
        /// </summary>
        public string Bitrate { get; set; }

        /// <summary>
        /// Maximum frames per second (e.g., "60").
        /// </summary>
        public string Framerate { get; set; }

        /// <summary>
        /// Output file format (e.g., "mp4", "mkv").
        /// </summary>
        public string OutputFormat { get; set; }

        /// <summary>
        /// Output filename without extension.
        /// </summary>
        public string OutputFile { get; set; }

        /// <summary>
        /// Initializes recording options with empty values.
        /// </summary>
        public ScreenRecordingOptions()
        {
            MaxSize = "";
            Bitrate = "";
            Framerate = "";
            OutputFormat = "";
            OutputFile = "";
        }

        /// <summary>
        /// Generates the command-line arguments for screen recording settings.
        /// </summary>
        /// <returns>Formatted command-line string with recording parameters.</returns>
        public string GenerateCommandPart()
        {
            try
            {
                string fullCommand = " ";
                fullCommand += !string.IsNullOrEmpty(MaxSize) ? $" --max-size={MaxSize}" : "";
                fullCommand += !string.IsNullOrEmpty(Bitrate) ? $" --video-bit-rate={Bitrate}" : "";
                fullCommand += !string.IsNullOrEmpty(Framerate) ? $" --max-fps={Framerate}" : "";
                fullCommand += !string.IsNullOrEmpty(OutputFormat) ? $" --record-format={OutputFormat}" : "";
                if (!string.IsNullOrEmpty(OutputFormat) && !string.IsNullOrEmpty(OutputFile))
                {
                    fullCommand += $" --record={OutputFile}.{OutputFormat}";
                }
                else if (string.IsNullOrEmpty(OutputFormat) && !string.IsNullOrEmpty(OutputFile))
                {
                    fullCommand += $" --record={OutputFile}.{OutputFormat}";
                }
                return fullCommand;
            }
            catch (Exception ex)
            {
                Debug.WriteLine($"Error in ScreenRecordingOptions.GenerateCommandPart: {ex.Message}");
                throw;
            }
        }
    }  
        
    /// <summary>
    /// Configuration options for virtual display functionality (Android 10+).
    /// Generates Scrcpy command-line parameters for virtual display settings.
    /// </summary>
    public class VirtualDisplayOptions
    {
        /// <summary>
        /// Whether to create a new virtual display.
        /// </summary>
        public bool NewDisplay { get; set; }

        /// <summary>
        /// Virtual display resolution (e.g., "1920x1080").
        /// </summary>
        public string Resolution { get; set; }

        /// <summary>
        /// Whether to prevent virtual display content from being destroyed on disconnection.
        /// </summary>
        public bool NoVdDestroyContent { get; set; }

        /// <summary>
        /// Whether to disable system decorations on the virtual display.
        /// </summary>
        public bool NoVdSystemDecorations { get; set; }

        /// <summary>
        /// Virtual display DPI value (e.g., "320").
        /// </summary>
        public string Dpi { get; set; }

        /// <summary>
        /// Initializes virtual display options with default values.
        /// </summary>
        public VirtualDisplayOptions()
        {
            NewDisplay = false;
            Resolution = "";
            NoVdDestroyContent = false;
            NoVdSystemDecorations = false;
            Dpi = "";
        }

        /// <summary>
        /// Generates the command-line arguments for virtual display settings.
        /// </summary>
        /// <returns>Formatted command-line string with virtual display parameters.</returns>
        public string GenerateCommandPart()
        {
            try
            {
                string fullCommand = " ";
                if (NewDisplay)
                {
                    fullCommand += " --new-display";
                    if (!string.IsNullOrEmpty(Resolution))
                    {
                        fullCommand += $"={Resolution}";
                        fullCommand += !string.IsNullOrEmpty(Dpi) ? $"/{Dpi}" : "";
                    }
                    else
                    {
                        fullCommand += !string.IsNullOrEmpty(Dpi) ? $"=/{Dpi}" : "";
                    }
                }
                fullCommand += NoVdDestroyContent ? $" --no-vd-destroy-content" : "";
                fullCommand += NoVdSystemDecorations ? $" --no-vd-system-decorations" : "";
                return fullCommand;
            }
            catch (Exception ex)
            {
                Debug.WriteLine($"Error in VirtualDisplayOptions.GenerateCommandPart: {ex.Message}");
                throw;
            }
        }
    }

    /// <summary>
    /// Configuration options for audio capture and playback.
    /// Generates Scrcpy command-line parameters for audio settings.
    /// </summary>
    public class AudioOptions
    {
        /// <summary>
        /// Audio bitrate value (e.g., "64000" or "64K").
        /// </summary>
        public string AudioBitRate { get; set; }

        /// <summary>
        /// Audio buffer size in milliseconds (e.g., "50").
        /// </summary>
        public string AudioBuffer { get; set; }

        /// <summary>
        /// Whether to duplicate audio output (Android 13+).
        /// </summary>
        public bool AudioDup { get; set; }

        /// <summary>
        /// Whether to disable audio capture.
        /// </summary>
        public bool NoAudio { get; set; }

        /// <summary>
        /// Custom codec options string.
        /// </summary>
        public string AudioCodecOptions { get; set; }

        /// <summary>
        /// Audio codec and encoder pair command (e.g., "--audio-codec=aac --audio-encoder=c2.android.aac.encoder").
        /// </summary>
        public string AudioCodecEncoderPair { get; set; }

        /// <summary>
        /// Initializes audio options with default values.
        /// </summary>
        public AudioOptions()
        {
            AudioBitRate = "";
            AudioBuffer = "";
            AudioDup = false;
            AudioCodecOptions = "";
            AudioCodecEncoderPair = "";
            NoAudio = false;
        }

        /// <summary>
        /// Generates the command-line arguments for audio settings.
        /// </summary>
        /// <returns>Formatted command-line string with audio parameters.</returns>
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
                Debug.WriteLine($"Error in AudioOptions.GenerateCommandPart: {ex.Message}");
                throw;
            }
        }
    }

    /// <summary>
    /// General configuration options for screen mirroring/casting.
    /// Generates Scrcpy command-line parameters for display and window settings.
    /// </summary>
    public class GeneralCastOptions
    {
        /// <summary>
        /// Whether to start in fullscreen mode.
        /// </summary>
        public bool Fullscreen { get; set; }

        /// <summary>
        /// Whether to turn off the device screen during mirroring.
        /// </summary>
        public bool TurnScreenOff { get; set; }

        /// <summary>
        /// Custom window title text.
        /// </summary>
        public string WindowTitle { get; set; }

        /// <summary>
        /// Crop parameters (e.g., "1920:1080:0:0").
        /// </summary>
        public string Crop { get; set; }

        /// <summary>
        /// Additional custom parameters to append to the command.
        /// </summary>
        public string ExtraParameters { get; set; }

        /// <summary>
        /// Video capture orientation (e.g., "0", "90", "180", "270").
        /// </summary>
        public string VideoOrientation { get; set; }

        /// <summary>
        /// Video codec and encoder pair command (e.g., "--video-codec=h265 --video-encoder=c2.qti.hevc.encoder").
        /// </summary>
        public string VideoCodecEncoderPair { get; set; }

        /// <summary>
        /// Whether to keep device awake during mirroring.
        /// </summary>
        public bool StayAwake { get; set; }

        /// <summary>
        /// Whether to remove window borders.
        /// </summary>
        public bool WindowBorderless { get; set; }

        /// <summary>
        /// Whether to keep window always on top.
        /// </summary>
        public bool WindowAlwaysOnTop { get; set; }

        /// <summary>
        /// Whether to disable screensaver during mirroring.
        /// </summary>
        public bool DisableScreensaver { get; set; }

        /// <summary>
        /// Video bitrate (e.g., "8M").
        /// </summary>
        public string VideoBitRate { get; set; }

        /// <summary>
        /// Initializes general cast options with default values.
        /// </summary>
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

        /// <summary>
        /// Generates the command-line arguments for general cast settings.
        /// </summary>
        /// <returns>Formatted command-line string with general parameters.</returns>
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
                fullCommand += !string.IsNullOrEmpty(ExtraParameters) ? $" {ExtraParameters}" : "";
                fullCommand += DisableScreensaver ? " --disable-screensaver" : "";
                return fullCommand;
            }
            catch (Exception ex)
            {
                Debug.WriteLine($"Error in GeneralCastOptions.GenerateCommandPart: {ex.Message}");
                throw;
            }
        }
    }

    /// <summary>
    /// Represents a connected Android device detected via ADB.
    /// Stores device identification, display name, and supported codec/encoder pairs.
    /// </summary>
    public class ConnectedDevice
    {
        /// <summary>
        /// Gets or sets the combined display name (e.g., "Pixel 6 - 192.168.1.100:5555" or "Pixel 6 - Serial123").
        /// </summary>
        public string CombinedName { get; set; }

        /// <summary>
        /// Gets or sets the device model name (e.g., "Pixel_6").
        /// </summary>
        public string DeviceName { get; set; }

        /// <summary>
        /// Gets or sets the unique device identifier (serial number or IP:port for wireless).
        /// </summary>
        public string DeviceId { get; set; }

        /// <summary>
        /// Gets or sets the list of supported audio codec and encoder combinations.
        /// </summary>
        public List<string> AudioCodecEncoderPairs { get; set; }

        /// <summary>
        /// Gets or sets the list of supported video codec and encoder combinations.
        /// </summary>
        public List<string> VideoCodecEncoderPairs { get; set; }

        /// <summary>
        /// Initializes a new instance with empty values.
        /// </summary>
        public ConnectedDevice()
        {
            CombinedName = "";
            DeviceName = "";
            DeviceId = "";
        }

        /// <summary>
        /// Initializes a new instance with specified values.
        /// </summary>
        /// <param name="combinedName">Combined display name.</param>
        /// <param name="deviceName">Device model name.</param>
        /// <param name="id">Device identifier.</param>
        public ConnectedDevice(string combinedName, string deviceName, string id)
        {
            this.CombinedName = combinedName;
            this.DeviceName = deviceName;
            this.DeviceId = id;
        }

        /// <summary>
        /// Determines whether the specified object is equal to the current device.
        /// </summary>
        /// <param name="obj">The object to compare.</param>
        /// <returns>True if the objects are equal; otherwise, false.</returns>
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

        /// <summary>
        /// Compares two device lists to determine if they contain the same device IDs.
        /// </summary>
        /// <param name="a">First device list.</param>
        /// <param name="b">Second device list.</param>
        /// <returns>True if both lists contain the same device IDs; otherwise, false.</returns>
        static public bool AreDeviceListsEqual(List<ConnectedDevice> a, List<ConnectedDevice> b)
        {
            var aSet = new HashSet<string>(a.Select(d => d.DeviceId));
            var bSet = new HashSet<string>(b.Select(d => d.DeviceId));
            return aSet.SetEquals(bSet);
        }

        /// <summary>
        /// Returns the hash code for this device.
        /// </summary>
        /// <returns>A hash code based on device properties.</returns>
        public override int GetHashCode()
        {
            return HashCode.Combine(CombinedName, DeviceName, DeviceId);
        }
    }
}