﻿using System;
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

        public ScrcpyGuiData(string mostRecentCommand, List<string> favoriteCommands)
        {
            MostRecentCommand = mostRecentCommand;
            FavoriteCommands = favoriteCommands ?? new List<string>();
        }

        public ScrcpyGuiData()
        {
            MostRecentCommand = "";
            FavoriteCommands = new List<string>();
        }
    }
    public class ScreenRecordingOptions
    {
        private static ScreenRecordingOptions? _instance;
        private static readonly object _lock = new object();

        public static ScreenRecordingOptions Instance
        {
            get
            {
                lock (_lock)
                {
                    if (_instance == null)
                    {
                        _instance = new ScreenRecordingOptions();
                    }
                    return _instance;
                }
            }
        }

        public string MaxSize { get; set; }
        public string Bitrate { get; set; }
        public string Framerate { get; set; }
        public string OutputFormat { get; set; }
        public string OutputFile { get; set; }

        private ScreenRecordingOptions()
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
                fullCommand += !string.IsNullOrEmpty(Bitrate) ? $" --bit-rate={Bitrate}" : "";
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
        private static VirtualDisplayOptions? _instance;
        private static readonly object _lock = new object();

        public static VirtualDisplayOptions Instance
        {
            get
            {
                lock (_lock)
                {
                    if (_instance == null)
                    {
                        _instance = new VirtualDisplayOptions();
                    }
                    return _instance;
                }
            }
        }

        public bool NewDisplay { get; set; }
        public string Resolution { get; set; }
        public bool NoVdDestroyContent { get; set; }
        public bool NoVdSystemDecorations { get; set; }
        public string Dpi { get; set; }

        private VirtualDisplayOptions()
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
        private static AudioOptions? _instance;
        private static readonly object _lock = new object();

        public static AudioOptions Instance
        {
            get
            {
                lock (_lock)
                {
                    if (_instance == null)
                    {
                        _instance = new AudioOptions();
                    }
                    return _instance;
                }
            }
        }

        public string AudioBitRate { get; set; } //64000 or 64K
        public string AudioBuffer { get; set; }
        public bool AudioDup { get; set; } // (Android 13+)
        public bool NoAudio{ get; set; }
        public string AudioCodecOptions { get; set; }
        public string AudioCodec { get; set; }

        private AudioOptions()
        {
            AudioBitRate = "";
            AudioBuffer = "";
            AudioDup = false;
            AudioCodecOptions = "";
            AudioCodec = "";
            NoAudio = false;
        }

        public string GenerateCommandPart()
        {
            try
            {
                string fullCommand = " ";
                fullCommand += !string.IsNullOrEmpty(AudioBitRate) ? $" --audio-bit-rate={AudioBitRate}" : "";
                fullCommand += !string.IsNullOrEmpty(AudioBuffer) ? $" --audio-buffer={AudioBuffer}" : "";
                fullCommand += !string.IsNullOrEmpty(AudioCodec) ? $" --audio-codec={AudioCodec}" : "";
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
        private static GeneralCastOptions? _instance;
        private static readonly object _lock = new object();

        public static GeneralCastOptions Instance
        {
            get
            {
                lock (_lock)
                {
                    if (_instance == null)
                    {
                        _instance = new GeneralCastOptions();
                    }
                    return _instance;
                }
            }
        }

        public bool Fullscreen { get; set; }
        public bool TurnScreenOff { get; set; }
        public string WindowTitle { get; set; }
        public string Crop { get; set; }
        public string VideoOrientation { get; set; }
        public bool StayAwake { get; set; }
        public bool WindowBorderless { get; set; }
        public bool WindowAlwaysOnTop { get; set; }
        //public string WindowPosition { get; set; }
        //public string WindowSize { get; set; }
        public bool DisableScreensaver { get; set; }

        private GeneralCastOptions()
        {
            Fullscreen = false;
            TurnScreenOff = false;
            WindowTitle = string.Empty;
            Crop = string.Empty;
            VideoOrientation = "";
            StayAwake = false;
            WindowBorderless = false;
            WindowAlwaysOnTop = false;
            //WindowPosition = string.Empty;
            //WindowSize = string.Empty;
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
                fullCommand += WindowBorderless ? " --window-borderless" : "";
                fullCommand += WindowAlwaysOnTop ? " --always-on-top" : "";
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
}