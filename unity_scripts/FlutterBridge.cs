using System;
using System.Collections;
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.Networking;
using TMPro;

/// <summary>
/// هذا السكريبت يربط واجهة Unity مع Flutter بعرض الاسم والنقاط وصورة الملف الشخصي
/// قم بربط هذا السكريبت بالـ GameObject المسسمى [MenuManager]
/// </summary>
public class FlutterBridge : MonoBehaviour
{
    private static FlutterBridge _instance;
    public static FlutterBridge Instance => _instance;

    [Header("UI References")]
    public TextMeshProUGUI playerNameText;
    public TextMeshProUGUI playerPointsText;
    public Image profileImage;

    [Header("بيانات اللاعب الحالية")]
    public string playerName = "اللاعب";
    public int playerPoints = 0;
    public string profilePicUrl = "";

    private void Awake()
    {
        if (_instance != null && _instance != this)
        {
            Destroy(gameObject);
            return;
        }
        _instance = this;
        DontDestroyOnLoad(gameObject);
    }

    private void Start()
    {
        // 1. القراءة الفورية من PlayerPrefs لضمان ظهور البيانات حتى قبل وصول رسالة الشوكة
        LoadFromPlayerPrefs();

        // 2. إعلام Flutter أن Unity جاهزة
        SendToFlutter("{\"action\":\"UnityReady\"}");
        SendToFlutter("{\"action\":\"setUserData\"}");
    }

    /// <summary>
    /// استقبال البيانات من Flutter عبر الدالة الرئيسية SetUserDataFromFlutter
    /// </summary>
    public void SetUserDataFromFlutter(string jsonMessage)
    {
        ProcessUserDataJson(jsonMessage);
    }

    /// <summary>
    /// استقبال البيانات عبر SetPlayerInfoFromFlutter (للتوافق المعياري)
    /// </summary>
    public void SetPlayerInfoFromFlutter(string jsonMessage)
    {
        ProcessUserDataJson(jsonMessage);
    }

    /// <summary>
    /// استقبال البيانات عبر SetUserData (اسم بديلي إضافي)
    /// </summary>
    public void SetUserData(string jsonMessage)
    {
        ProcessUserDataJson(jsonMessage);
    }

    private void ProcessUserDataJson(string jsonMessage)
    {
        try
        {
            Debug.Log($"FlutterBridge: Received JSON: {jsonMessage}");
            var payload = JsonUtility.FromJson<UserDataPayload>(jsonMessage);

            if (payload != null)
            {
                playerName = !string.IsNullOrEmpty(payload.name) ? payload.name : "اللاعب";
                playerPoints = payload.points >= 0 ? payload.points : 0;
                profilePicUrl = !string.IsNullOrEmpty(payload.profilePic) ? payload.profilePic : payload.imageUrl;

                // حفظ في PlayerPrefs للسرعة المستقبليّة
                SaveToPlayerPrefs();

                // تحديث واجهة المستخدم
                UpdateUI();
            }
        }
        catch (Exception e)
        {
            Debug.LogError($"FlutterBridge: Error processing JSON: {e.Message}");
        }
    }

    private void UpdateUI()
    {
        // تحديث نص الاسم
        if (playerNameText != null)
        {
            playerNameText.text = playerName;
        }

        // تحديث نص النقاط
        if (playerPointsText != null)
        {
            playerPointsText.text = playerPoints.ToString();
        }

        // تحميل صورة الملف الشخصي من الرابط
        if (profileImage != null && !string.IsNullOrEmpty(profilePicUrl))
        {
            StartCoroutine(DownloadImage(profilePicUrl));
        }
    }

    private IEnumerator DownloadImage(string url)
    {
        using (UnityWebRequest request = UnityWebRequestTexture.GetTexture(url))
        {
            yield return request.SendWebRequest();

            if (request.result == UnityWebRequest.Result.Success)
            {
                Texture2D texture = ((DownloadHandlerTexture)request.downloadHandler).texture;
                Sprite sprite = Sprite.Create(
                    texture,
                    new Rect(0, 0, texture.width, texture.height),
                    new Vector2(0.5f, 0.5f)
                );

                if (profileImage != null)
                {
                    profileImage.sprite = sprite;
                }
            }
            else
            {
                Debug.LogWarning($"FlutterBridge: Failed to load profile image: {request.error}");
            }
        }
    }

    private void SaveToPlayerPrefs()
    {
        PlayerPrefs.SetString("playerName", playerName);
        PlayerPrefs.SetInt("playerPoints", playerPoints);
        PlayerPrefs.SetString("playerPhotoUrl", profilePicUrl);
        PlayerPrefs.Save();
    }

    private void LoadFromPlayerPrefs()
    {
        playerName = PlayerPrefs.GetString("playerName", "اللاعب");
        playerPoints = PlayerPrefs.GetInt("playerPoints", 100);
        profilePicUrl = PlayerPrefs.GetString("playerPhotoUrl", "");
        UpdateUI();
    }

    private void SendToFlutter(string jsonMessage)
    {
#if UNITY_ANDROID && !UNITY_EDITOR
        try
        {
            using (var javaClass = new AndroidJavaClass("com.royaldoor.live.MainActivity"))
            {
                javaClass.CallStatic("sendUnityMessageToFlutter", jsonMessage);
            }
        }
        catch (Exception e)
        {
            Debug.LogError($"FlutterBridge: Failed to send to Flutter: {e.Message}");
        }
#else
        Debug.Log($"FlutterBridge (Editor): Sending to Flutter: {jsonMessage}");
#endif
    }

    [Serializable]
    private class UserDataPayload
    {
        public string action;
        public string name;
        public string profilePic;
        public string imageUrl;
        public int points;
        public int entryCost;
        public int winReward;
        public string gameId;
    }
}
