﻿using Microsoft.Extensions.Logging;
using Microsoft.Maui.LifecycleEvents;
using CommunityToolkit.Maui;
using UraniumUI;
using UraniumUI.Material;
using System.Threading;
using System.Diagnostics;
#if WINDOWS
using Microsoft.UI.Windowing;
using Microsoft.UI.Xaml;
using Windows.Graphics;
#endif

namespace ScrcpyGUI
{
    public static class MauiProgram
    {
        private static Mutex? _mutex;
        private const string MutexName = "ScrcpyGUI_SingleInstance_Mutex";

        public static MauiApp CreateMauiApp()
        {
            // Check for single instance before creating the app
            if (!CheckSingleInstance())
            {
                // Another instance is already running
                Environment.Exit(0);
                return null!; // This won't be reached, but satisfies the compiler
            }

            var builder = MauiApp.CreateBuilder();
            builder
                .UseMauiApp<App>()
                .ConfigureFonts(fonts =>
                {
                    fonts.AddFont("OpenSans-Regular.ttf", "OpenSansRegular");
                    fonts.AddFont("OpenSans-Semibold.ttf", "OpenSansSemibold");
                    fonts.AddFont("FontAwesomeFree-Solid-900.otf", "FontAwesome");
                    fonts.AddFont("Font Awesome 6 Free-Regular-400.otf", "FontAwesomeFreeRegular");
                    fonts.AddFont("Font Awesome 6 Brands-Regular-400.otf", "FontAwesomeBrandsRegular");
                    fonts.AddFont("OpenSans-Regular.ttf", "OpenSansRegular");
                    fonts.AddFont("OpenSans-Semibold.ttf", "OpenSansSemibold");
                    fonts.AddFont("MaterialIcons-Regular.ttf", "MaterialRegular");
                    fonts.AddMaterialIconFonts(); // For Material Icons
                })
                .ConfigureMauiHandlers(handlers =>
                {
                    handlers.AddUraniumUIHandlers(); // Enable Uranium UI
                })
                .UseUraniumUI()
                .UseUraniumUIMaterial()
                .UseMauiCommunityToolkit();

#if WINDOWS
            builder.ConfigureLifecycleEvents(events =>
            {
                events.AddWindows(windows =>
                {
                    windows.OnWindowCreated(window =>
                    {
                        var nativeWindow = window as MauiWinUIWindow;
                        if (nativeWindow != null)
                        {
                            // Use reflection to access the MinimumSize property of IPlatformSizeRestrictedWindow  
                            var sizeRestrictedWindowInterface = typeof(MauiWinUIWindow).GetInterface("IPlatformSizeRestrictedWindow", true);
                            if (sizeRestrictedWindowInterface != null)
                            {
                                var minimumSizeProperty = sizeRestrictedWindowInterface.GetProperty("MinimumSize");
                                if (minimumSizeProperty != null)
                                {
                                    var sizeValue = new SizeInt32 { Width = 800, Height = 600 };
                                    minimumSizeProperty.SetValue(nativeWindow, sizeValue);
                                }
                            }
                        }
                    });
                });
            });
#endif

#if DEBUG
            builder.Logging.AddDebug();
#endif
            return builder.Build();
        }

        private static bool CheckSingleInstance()
        {
            try
            {
                // Try to create a mutex with a unique name for your application
                _mutex = new Mutex(true, MutexName, out bool createdNew);

                if (!createdNew)
                {
                    // Another instance is already running
                    _mutex?.Dispose();
                    _mutex = null;

                    // Optional: Try to bring the existing instance to foreground
                    BringExistingInstanceToForeground();

                    return false;
                }

                return true;
            }
            catch (Exception ex)
            {
                // If there's an error with mutex creation, allow the app to start
                Debug.WriteLine($"Error checking single instance: {ex.Message}");
                return true;
            }
        }

        private static void BringExistingInstanceToForeground()
        {
            try
            {
                // Find the existing process by name
                var currentProcess = Process.GetCurrentProcess();
                var processes = Process.GetProcessesByName(currentProcess.ProcessName);

                foreach (var process in processes)
                {
                    if (process.Id != currentProcess.Id && process.MainWindowHandle != IntPtr.Zero)
                    {
#if WINDOWS
                        // Windows-specific code to bring window to foreground
                        Win32Helper.BringWindowToForeground(process.MainWindowHandle);
#endif
                        break;
                    }
                }
            }
            catch (Exception ex)
            {
                Debug.WriteLine($"Error bringing existing instance to foreground: {ex.Message}");
            }
        }

        // Clean up the mutex when the application exits
        public static void CleanupMutex()
        {
            _mutex?.ReleaseMutex();
            _mutex?.Dispose();
            _mutex = null;
        }
    }

#if WINDOWS
    // Helper class for Windows-specific operations
    internal static class Win32Helper
    {
        [System.Runtime.InteropServices.DllImport("user32.dll")]
        private static extern bool SetForegroundWindow(IntPtr hWnd);

        [System.Runtime.InteropServices.DllImport("user32.dll")]
        private static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

        [System.Runtime.InteropServices.DllImport("user32.dll")]
        private static extern bool IsIconic(IntPtr hWnd);

        private const int SW_RESTORE = 9;
        private const int SW_SHOW = 5;

        public static void BringWindowToForeground(IntPtr windowHandle)
        {
            if (IsIconic(windowHandle))
            {
                ShowWindow(windowHandle, SW_RESTORE);
            }
            else
            {
                ShowWindow(windowHandle, SW_SHOW);
            }
            SetForegroundWindow(windowHandle);
        }
    }
#endif
}