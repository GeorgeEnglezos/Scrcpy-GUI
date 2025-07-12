using Microsoft.Maui.Storage;
using Newtonsoft.Json;
using ScrcpyGUI.Models;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Text;

public static class DataStorage
{
    public static ScrcpyGuiData staticSavedData { get; set; } = new ScrcpyGuiData();
    public static readonly string settingsPath = Path.Combine(FileSystem.AppDataDirectory, "ScrcpyGui-Data.json");

    public static ScrcpyGuiData LoadData()
    {
        try
        {
            if (!File.Exists(settingsPath))
            {
                // File doesn't exist, create it with default data
                SaveData(new ScrcpyGuiData()); // Ensure it's created
                return staticSavedData;
            }

            var jsonString = File.ReadAllText(settingsPath, Encoding.UTF8);
            staticSavedData = JsonConvert.DeserializeObject<ScrcpyGuiData>(jsonString) ?? new ScrcpyGuiData();
            return staticSavedData;
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Failed to load data: {ex.Message}");
            return new ScrcpyGuiData(); // Fallback
        }
    }

    public static void SaveData(ScrcpyGuiData data)
    {
        try
        {
            // Ensure directory exists
            var dir = Path.GetDirectoryName(settingsPath);
            var directoryExists = File.Exists(dir);
            if (!directoryExists)
                CreateFile();

            staticSavedData = data;
            var jsonString = JsonConvert.SerializeObject(data, Formatting.Indented);
            File.WriteAllText(settingsPath, jsonString, Encoding.UTF8);
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Failed to save data: {ex.Message}");
        }
    }

    private static void CreateFile()
    {
        try
        {
            var dir = Path.GetDirectoryName(settingsPath);
            if (!Directory.Exists(dir))
            {
                Directory.CreateDirectory(dir);
            }

            if (!File.Exists(settingsPath))
            {
                File.WriteAllText(settingsPath, "{}"); // Avoid deserialization issues
            }
        }
        catch (Exception ex)
        {
            // Log or handle error as needed
            Console.WriteLine($"Failed to create file: {ex.Message}");
            throw;
        }
    }



    public static void AppendFavoriteCommand(string newCommand)
    {
        var data = LoadData();
        data.FavoriteCommands.Add(newCommand);
        SaveData(data);        
    }

    public static bool RemoveFavoriteCommandAtIndex(int index, ScrcpyGuiData data)
    {
        if (index >= 0 && index < data.FavoriteCommands.Count)
        {
            data.FavoriteCommands.RemoveAt(index);
            SaveData(data);
            return true;
        }
        return false;
    }

    public static void SaveMostRecentCommand(string command)
    {
        var data = LoadData();
        data.MostRecentCommand = command;
        SaveData(data);
    }

    public static void ClearAll()
    {
        if (File.Exists(settingsPath))
        {
            File.Delete(settingsPath);
        }
    }

    public static string ValidateAndCreatePath(string folderPath, string fallbackPath = null)
    {
        // If the path is null or empty, use fallback or return empty string
        if (string.IsNullOrWhiteSpace(folderPath))
        {
            return fallbackPath ?? string.Empty;
        }
        try
        {
            if (!Directory.Exists(folderPath))
            {
                Directory.CreateDirectory(folderPath);
            }
            return folderPath;
        }
        catch (Exception ex)
        {
            Debug.WriteLine($"Failed to create directory '{folderPath}': {ex.Message}");
            return fallbackPath ?? string.Empty;
        }
    }
}