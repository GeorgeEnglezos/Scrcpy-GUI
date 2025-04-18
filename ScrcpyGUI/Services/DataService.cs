using Newtonsoft.Json;
using ScrcpyGUI.Models;
using System;
using System.Collections.Generic;
using System.IO;

public static class DataStorage
{
    private static readonly string FilePath = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments), "ScrcpyGui-Data.json");

    // Load the ScrcpyGuiData
    public static ScrcpyGuiData LoadData()
    {
        if (!File.Exists(FilePath))
        {
            return new ScrcpyGuiData();
        }

        string jsonString = File.ReadAllText(FilePath);
        return JsonConvert.DeserializeObject<ScrcpyGuiData>(jsonString) ?? new ScrcpyGuiData();
    }

    // Save the ScrcpyGuiData to a file
    public static void SaveData(ScrcpyGuiData data)
    {
        string jsonString = JsonConvert.SerializeObject(data);
        File.WriteAllText(FilePath, jsonString);
    }

    // Append a new command to the FavoriteCommands list
    public static void AppendCommand(string newCommand)
    {
        var data = LoadData();
        data.FavoriteCommands.Add(newCommand);
        SaveData(data);
    }

    // Remove a command at a specific index
    public static bool RemoveCommandAtIndex(int index)
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
        if (File.Exists(FilePath))
        {
            File.Delete(FilePath);
        }
    }
}
