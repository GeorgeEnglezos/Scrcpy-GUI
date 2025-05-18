using Newtonsoft.Json;
using ScrcpyGUI.Models;
using System;
using System.Collections.Generic;
using System.IO;

public static class DataStorage
{
    private static readonly string filePath = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments), "ScrcpyGui-Data.json");
    public static ScrcpyGuiData staticSavedData { get; set; } = new ScrcpyGuiData();

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

    public static void SaveData(ScrcpyGuiData data)
    {
        staticSavedData = data;
        string jsonString = JsonConvert.SerializeObject(data);
        File.WriteAllText(filePath, jsonString);
    }

    public static void AppendFavoriteCommand(string newCommand)
    {
        var data = LoadData();
        data.FavoriteCommands.Add(newCommand);
        SaveData(data);
    }

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

    public static void SaveMostRecentCommand(string command)
    {
        var data = LoadData();
        data.MostRecentCommand = command;
        SaveData(data);
    }

    public static void ClearAll()
    {
        if (File.Exists(filePath))
        {
            File.Delete(filePath);
        }
    }
}
