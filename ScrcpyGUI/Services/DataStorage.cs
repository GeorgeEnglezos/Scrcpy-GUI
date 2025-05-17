using Newtonsoft.Json;
using ScrcpyGUI.Models;
using System;
using System.Collections.Generic;
using System.IO;

public static class DataStorage
{
    private static readonly string filePath = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments), "ScrcpyGui-Data.json");
    public static ScrcpyGuiData staticSavedData { get; set; } = new ScrcpyGuiData();

    // Load the ScrcpyGuiData
    public static ScrcpyGuiData LoadData()
    {
        if (!File.Exists(filePath))
        {
            return new ScrcpyGuiData();
        }

        string jsonString = File.ReadAllText(filePath);
        staticSavedData = JsonConvert.DeserializeObject<ScrcpyGuiData>(jsonString) ?? new ScrcpyGuiData();
        return staticSavedData;
    }

    // Save the ScrcpyGuiData to a file
    public static void SaveData(ScrcpyGuiData data)
    {
        staticSavedData = data;
        string jsonString = JsonConvert.SerializeObject(data);
        File.WriteAllText(filePath, jsonString);
    }

    // Append a new command to the FavoriteCommands list
    public static void AppendFavoriteCommand(string newCommand)
    {
        var data = LoadData();
        data.FavoriteCommands.Add(newCommand);
        SaveData(data);
    }

    // Remove a command at a specific index
    public static bool RemoveFavoriteCommandAtIndex(int index)
    {
        var data = LoadData();
        if (index >= 0 && index < data.FavoriteCommands.Count)
        {
            data.FavoriteCommands.RemoveAt(index);
            SaveData(data);
            return true;
        }
        return false;
    }

    // Save the most recent command
    public static void SaveMostRecentCommand(string command)
    {
        var data = LoadData();
        data.MostRecentCommand = command;
        SaveData(data);
    }

    // Clear all saved data
    public static void ClearAll()
    {
        if (File.Exists(filePath))
        {
            File.Delete(filePath);
        }
    }
}
