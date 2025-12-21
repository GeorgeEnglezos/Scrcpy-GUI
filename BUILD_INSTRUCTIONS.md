# Build and Run Instructions

## Build the Application

To build the application for release:

```bash
dotnet publish -c Release -f net9.0-windows10.0.19041.0 -p:PublishSingleFile=true
```

**Note:** The following parameters might cause issues and should be used with caution:
- `-p:SelfContained=true`
- `-p:PublishTrimmed=true`

## Run the Application (Development)

To run the application during development:

```bash
dotnet run -f net9.0-windows10.0.19041.0
```

Or with the build target (alternative method):

```bash
dotnet build -t:Run -f net9.0-windows10.0.19041.0
```

## Prerequisites

- .NET SDK 9.0 or later
- .NET MAUI workloads installed:
  - `maui-windows`
  - `maui-android` (optional)
  - `maui-ios` (optional)
  - `maui-maccatalyst` (optional)

To install MAUI workloads:

```bash
dotnet workload install maui
```

## Platform Target

This project is configured for Windows 10.0.19041.0 (Windows 10, version 2004) and later.
