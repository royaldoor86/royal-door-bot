using System;
using UnityEngine;
using UnityEngine.UI;

/// <summary>
/// جسر موحد بين Flutter و Unity لإدارة الألعاب المتعددة ونظام النقاط
/// Attach this script to a persistent GameObject in Unity named "PlayerInfoManager" or "GameManager"
/// </summary>
public class UnityMultiGameBridge : MonoBehaviour
{
    private static UnityMultiGameBridge _instance;
    public static UnityMultiGameBridge Instance => _instance;

    [Header("بيانات اللاعب الحالية")]
    public string playerName = "اللاعب";
    public string profilePicUrl = "";
    public int currentPoints = 0;
    public int entryCost = 100;
    public int winReward = 200;

    [Header("بيانات اللعبة الحالية")]
    public string gameId = "royal_snake";
    public string gameName = "Royal Snake";
    public string bundlePath = "";
    public string sceneName = "";

    [Header("عناصر الواجهة (اختياري)")]
    public Text nameText;
    public Text pointsText;
    public Text entryCostText;
    public Text winRewardText;

    private void Awake()
    {
        if (_instance != null && _instance != this)
        {
            Destroy(gameObject);
            return;
        }
        _instance = this;
        DontDestroyOnLoad(gameObject);

        // قراءة البيانات الابتدائية من PlayerPrefs إن وجدت
        LoadFromPlayerPrefs();
    }

    private void Start()
    {
        // إعلام Flutter أن Unity جاهزة للاستلام
        SendToFlutter("{\"action\":\"UnityReady\"}");
    }

    /// <summary>
    /// يتم استدعاؤها مباشرة من Flutter عند فتح أي لعبة
    /// Target: "PlayerInfoManager", Method: "SetUserDataFromFlutter"
    /// </summary>
    public void SetUserDataFromFlutter(string jsonMessage)
    {
        try
        {
            Debug.Log($"UnityMultiGameBridge: Received payload from Flutter: {jsonMessage}");
            var payload = JsonUtility.FromJson<UserDataPayload>(jsonMessage);

            if (payload != null)
            {
                playerName = string.IsNullOrEmpty(payload.name) ? "اللاعب" : payload.name;
                profilePicUrl = payload.profilePic ?? "";
                currentPoints = Mathf.Max(0, payload.points);
                entryCost = payload.entryCost > 0 ? payload.entryCost : 100;
                winReward = payload.winReward > 0 ? payload.winReward : 200;

                if (!string.IsNullOrEmpty(payload.gameId)) gameId = payload.gameId;
                if (!string.IsNullOrEmpty(payload.gameName)) gameName = payload.gameName;
                if (!string.IsNullOrEmpty(payload.bundlePath)) bundlePath = payload.bundlePath;
                if (!string.IsNullOrEmpty(payload.sceneName)) sceneName = payload.sceneName;

                SaveToPlayerPrefs();
                UpdateUI();
            }
        }
        catch (Exception e)
        {
            Debug.LogError($"UnityMultiGameBridge: Error parsing user data from Flutter: {e.Message}");
        }
    }

    /// <summary>
    /// يتم استدعاؤها عند فوز اللاعب في اللعبة لتحديث النقاط في Flutter و Firestore
    /// </summary>
    public void OnPlayerWon()
    {
        currentPoints += winReward;
        UpdateUI();
        SaveToPlayerPrefs();

        var message = JsonUtility.ToJson(new GameEventPayload
        {
            action = "PlayerWon",
            gameId = gameId,
            reward = winReward,
            currentPoints = currentPoints
        });

        SendToFlutter(message);
        Debug.Log($"UnityMultiGameBridge: Player WON. Sent reward {winReward} to Flutter.");
    }

    /// <summary>
    /// يتم استدعاؤها عند خسارة اللاعب في اللعبة
    /// </summary>
    public void OnPlayerLost()
    {
        var message = JsonUtility.ToJson(new GameEventPayload
        {
            action = "PlayerLost",
            gameId = gameId,
            reward = 0,
            currentPoints = currentPoints
        });

        SendToFlutter(message);
        Debug.Log("UnityMultiGameBridge: Player LOST.");
    }

    /// <summary>
    /// إغلاق اللعبة والعودة إلى تطبيق Flutter
    /// </summary>
    public void CloseGameAndReturnToFlutter()
    {
        var message = JsonUtility.ToJson(new GameEventPayload
        {
            action = "close_unity",
            gameId = gameId,
        });

        SendToFlutter(message);
    }

    private void SendToFlutter(string jsonString)
    {
#if UNITY_ANDROID && !UNITY_EDITOR
        try
        {
            using (var javaClass = new AndroidJavaClass("com.royaldoor.live.MainActivity"))
            {
                javaClass.CallStatic("sendUnityMessageToFlutter", jsonString);
            }
        }
        catch (Exception e)
        {
            Debug.LogError($"UnityMultiGameBridge: Failed to send to Android Flutter: {e.Message}");
        }
#else
        Debug.Log($"UnityMultiGameBridge (Editor Sim): Sending to Flutter: {jsonString}");
#endif
    }

    private void UpdateUI()
    {
        if (nameText != null) nameText.text = playerName;
        if (pointsText != null) pointsText.text = currentPoints.ToString();
        if (entryCostText != null) entryCostText.text = entryCost.ToString();
        if (winRewardText != null) winRewardText.text = winReward.ToString();
    }

    private void SaveToPlayerPrefs()
    {
        PlayerPrefs.SetString("playerName", playerName);
        PlayerPrefs.SetString("playerPhotoUrl", profilePicUrl);
        PlayerPrefs.SetInt("playerPoints", currentPoints);
        PlayerPrefs.SetInt("entryCost", entryCost);
        PlayerPrefs.SetInt("winReward", winReward);
        PlayerPrefs.SetString("gameId", gameId);
        PlayerPrefs.SetString("bundlePath", bundlePath);
        PlayerPrefs.Save();
    }

    private void LoadFromPlayerPrefs()
    {
        playerName = PlayerPrefs.GetString("playerName", "اللاعب");
        profilePicUrl = PlayerPrefs.GetString("playerPhotoUrl", "");
        currentPoints = PlayerPrefs.GetInt("playerPoints", 0);
        entryCost = PlayerPrefs.GetInt("entryCost", 100);
        winReward = PlayerPrefs.GetInt("winReward", 200);
        gameId = PlayerPrefs.GetString("gameId", "royal_snake");
        bundlePath = PlayerPrefs.GetString("bundlePath", "");
        UpdateUI();
    }

    [Serializable]
    private class UserDataPayload
    {
        public string action;
        public string name;
        public string profilePic;
        public int points;
        public int entryCost;
        public int winReward;
        public string gameId;
        public string gameName;
        public string bundlePath;
        public string sceneName;
    }

    [Serializable]
    private class GameEventPayload
    {
        public string action;
        public string gameId;
        public int reward;
        public int currentPoints;
    }
}
