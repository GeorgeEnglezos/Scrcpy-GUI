using Microsoft.Extensions.Logging;
using Microsoft.Maui.LifecycleEvents;
using CommunityToolkit.Maui;
using UraniumUI;
using UraniumUI.Material;
#if WINDOWS
using Microsoft.UI.Windowing;
using Microsoft.UI.Xaml;
using Windows.Graphics;

#endif

namespace ScrcpyGUI
{
    public static class MauiProgram
    {
        public static MauiApp CreateMauiApp()
        {
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
    }
}
