import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import axios from "axios";

const TELEGRAM_TOKEN = process.env.TELEGRAM_BOT_TOKEN;
const TELEGRAM_API = `https://api.telegram.org/bot${TELEGRAM_TOKEN}`;

interface TelegramMessage {
  message_id: number;
  chat: { id: number };
  from: { id: number; first_name: string; username?: string; last_name?: string };
  text?: string;
  photo?: any[];
  contact?: { phone_number: string; user_id: number; first_name: string };
}

interface TelegramCallback {
  callback_query: {
    id: string;
    from: { id: number; first_name: string };
    message: { message_id: number; chat: { id: number } };
    data: string;
  };
}

const db = admin.firestore();

/**
 * 🛡️ Request Phone Verification
 */
async function handleRequestVerification(chat_id: number) {
  await axios.post(`${TELEGRAM_API}/sendMessage`, {
    chat_id,
    text: "🛡️ **خطوة الأمان الملكية**\n\nلمنع الحسابات الوهمية وضمان جودة الخدمة، يرجى الضغط على الزر أدناه لمشاركة رقم هاتفك الموثق في تلجرام.\n\nسيتم فتح ميزة 'تطبيقي الملكي' فور التحقق.",
    reply_markup: {
      keyboard: [
        [{ text: "📱 مشاركة رقم الهاتف للتحقق", request_contact: true }]
      ],
      resize_keyboard: true,
      one_time_keyboard: true
    }
  });
}

/**
 * 🛠 Helper to escape HTML characters
 */
function escapeHTML(str: string): string {
  if (!str) return "";
  return str
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#039;");
}

/**
 * 🤖 Main Telegram Bot Handler
 */
export const telegramBotHandler = functions
  .region("us-central1")
  .runWith({
    minInstances: 1,
    timeoutSeconds: 540,
  })
  .https.onRequest(async (req, res) => {
    try {
      console.log('🚀 Telegram Bot Handler called');
      console.log('📝 Request body:', JSON.stringify(req.body));
      
      const body = req.body;

      // 1️⃣ Handle Message Reactions (New!)
      if (body.message_reaction) {
        const reaction = body.message_reaction;
        const chat_id = reaction.user.id;
        const message_id = reaction.message_id;

        // Only reward if they added a reaction (not removed)
        if (reaction.new_reaction && reaction.new_reaction.length > 0) {
          await handleReactionReward(chat_id, message_id);
        }
      }

      // 2️⃣ Handle standard message
      if (body.message) {
        const msg = body.message as TelegramMessage;
        const chat_id = msg.chat.id;
        const text = msg.text;
        const user = msg.from;

        if (msg.contact) {
          await handleContactMessage(chat_id, msg.contact);
        } else if (text?.startsWith("/start")) {
          const parts = text.split(" ");
          if (parts.length > 1) {
            const param = parts[1];
            if (param.startsWith("link_")) {
              const appUid = param.replace("link_", "");
              await handleAccountLinking(chat_id, appUid, user);
            } else {
              await handleReferralPoints(chat_id, param);
            }
          }
          await handleStartCommand(chat_id, user);
        } else {
          // Check for Admin Inputs or State-based inputs
          const userRef = db.collection("telegram_users").doc(chat_id.toString());
          const userDoc = await userRef.get();
          const userData = userDoc.data();

          if (userData?.waiting_for_link) {
            await processFundingLink(chat_id, text || "");
          } else if (userData?.admin_state) {
            await handleAdminInputs(chat_id, text || "", userData.admin_state, msg.photo);
          } else if (userData?.user_state) {
            await handleUserStateInputs(chat_id, text || "", userData.user_state, msg.photo);
          } else if (text?.startsWith("/")) {
            await handleCommand(chat_id, text, user);
          } else if (text?.startsWith("http") || text?.startsWith("@")) {
            await handleCommand(chat_id, text, user);
          }
        }
      }

      // 3️⃣ Handle callback query
      if (body.callback_query) {
        const cb = body.callback_query;
        const chat_id = cb.message.chat.id;
        const message_id = cb.message.message_id;
        const data = cb.data;

        // Answer callback immediately to stop the loading spinner (prevent freeze)
        await axios.post(`${TELEGRAM_API}/answerCallbackQuery`, {
          callback_query_id: cb.id,
          show_alert: false,
        }).catch(err => console.error("Callback Answer Error:", err));

        switch (data) {
          case "play_games":
            await handlePlayGames(chat_id, message_id);
            break;
          case "royal_services":
            await handleRoyalServices(chat_id, message_id);
            break;
          case "news":
            await handleNews(chat_id, message_id);
            break;
          case "more_packages":
            await handleMorePackages(chat_id, message_id);
            break;
          case "header_agencies":
          case "agencies_menu":
            await handleAgenciesMenu(chat_id, message_id);
            break;
          case "investment":
            await handleInvestment(chat_id, message_id);
            break;
          case "media_center_menu":
            await handleMediaCenterMenu(chat_id, message_id);
            break;
          case "offers":
            await handleOffers(chat_id, message_id);
            break;
          case "royal_ids":
            await handleRoyalIDs(chat_id, message_id);
            break;
          case "admin_panel":
            await handleAdminPanel(chat_id, message_id);
            break;
          case "request_verification":
            await handleRequestVerification(chat_id);
            break;
          case "admin_charge_points":
            await askForTargetUserId(chat_id, "charge");
            break;
          case "admin_deduct_points":
            await askForTargetUserId(chat_id, "deduct");
            break;
          case "admin_broadcast":
            await askForBroadcastMessage(chat_id);
            break;
          case "admin_create_news":
            await startAdminCreation(chat_id, "news");
            break;
          case "admin_create_offer":
            await startAdminCreation(chat_id, "offer");
            break;
          case "admin_create_contest":
            await startAdminCreation(chat_id, "contest");
            break;
          case "admin_create_vip":
            await startAdminCreation(chat_id, "vip");
            break;
          case "admin_promo_fund":
            await askForPromoLink(chat_id);
            break;
          case "admin_system_stats":
            await handleSystemStats(chat_id, message_id);
            break;
          case "admin_bot_users":
            await handleAdminBotUsers(chat_id, message_id);
            break;
          case "contests":
            await handleContests(chat_id, message_id);
            break;
          case "transfer_to_user":
            await handleUserTransferStart(chat_id);
            break;
          case "convert_to_app_gems":
            await handleAppConversionStart(chat_id, 'gems');
            break;
          case "convert_to_app_coins":
            await handleAppConversionStart(chat_id, 'coins');
            break;
          case "help_menu":
            await handleHelp(chat_id, message_id);
            break;
          case "technical_support":
            await handleTechnicalSupport(chat_id, message_id);
            break;
          case "buy_durra":
            await handlePurchasePackage(chat_id, "durra");
            break;
          case "buy_morjan":
            await handlePurchasePackage(chat_id, "morjan");
            break;
          case "buy_aqeeq":
            await handlePurchasePackage(chat_id, "aqeeq");
            break;
          case "buy_crystal":
            await handlePurchasePackage(chat_id, "crystal");
            break;
          case "buy_zabarjad":
            await handlePurchasePackage(chat_id, "zabarjad");
            break;
          case "buy_lulu":
            await handlePurchasePackage(chat_id, "lulu");
            break;
          case "buy_fayrouz":
            await handlePurchasePackage(chat_id, "fayrouz");
            break;
          case "buy_almas":
            await handlePurchasePackage(chat_id, "almas");
            break;
          case "buy_zumurrud":
            await handlePurchasePackage(chat_id, "zumurrud");
            break;
          case "buy_yaqoot":
            await handlePurchasePackage(chat_id, "yaqoot");
            break;
          case "vip":
            await handleVIP(chat_id, message_id);
            break;
          case "upgrade_membership":
            await handleUpgradeLogic(chat_id);
            break;
          case "buy_points":
            await handleBuyPointsMenu(chat_id, message_id);
            break;
          case "stats":
            await handleStats(chat_id, message_id);
            break;
          case "leaderboard":
          case "leaderboard_interactions":
            await handleLeaderboard(chat_id, message_id, "interactions");
            break;
          case "leaderboard_donors":
            await handleLeaderboard(chat_id, message_id, "donors");
            break;
          case "leaderboard_referrals":
            await handleLeaderboard(chat_id, message_id, "referrals");
            break;
          case "convert_to_gems_100":
            await handleConversion(chat_id, 100, 10, 'gems');
            break;
          case "convert_to_coins_100":
            await handleConversion(chat_id, 100, 20, 'coins');
            break;
          case "convert_to_gems_500":
            await handleConversion(chat_id, 500, 50, 'gems');
            break;
          case "convert_to_coins_1000":
            await handleConversion(chat_id, 500, 100, 'coins');
            break;
          case "treasury":
            await handleTreasury(chat_id, message_id);
            break;
          case "voice_rooms":
            await handleVoiceRooms(chat_id, message_id);
            break;
          case "header_interaction":
          case "interaction_menu":
            await handleInteractionMenu(chat_id, message_id);
            break;
          case "referrals":
            await handleReferrals(chat_id, message_id);
            break;
          case "share_sm_info":
            await handleShareSMInfo(chat_id);
            break;
          case "promoted_list":
            await handlePromotedList(chat_id, message_id);
            break;
          case "about":
            await handleAbout(chat_id, message_id);
            break;
          case "view_privacy":
            await handleViewPrivacy(chat_id, message_id);
            break;
          case "view_terms":
            await handleViewTerms(chat_id, message_id);
            break;
          case "faq":
            await handleFAQ(chat_id, message_id);
            break;
          case "verify_channel":
            await verifyTask(chat_id, "join_channel", 5, "@royaldur");
            break;
          case "verify_group":
            await verifyTask(chat_id, "join_group", 5, "@royaldoor");
            break;
          case "verify_tiktok":
            await verifyTask(chat_id, "follow_tiktok", 10);
            break;
          case "verify_facebook":
            await verifyTask(chat_id, "follow_facebook", 10);
            break;
          case "daily_claim":
            await verifyTask(chat_id, "daily_reward_claim_" + new Date().toISOString().split('T')[0], 2);
            break;
          case "balance":
            await handleBalance(chat_id, message_id);
            break;
          case "profile":
            await handleProfile(chat_id, message_id);
            break;
          case "account_menu":
            await handleAccountMenu(chat_id, message_id);
            break;
          case "daily_rewards_menu":
            await handleDailyRewardsMenu(chat_id, message_id);
            break;
          case "harvest_daily_points":
            await handleHarvestPoints(chat_id);
            break;
          case "header_account":
            await handleAccountMenu(chat_id, message_id);
            break;
          case "funding":
            await handleFunding(chat_id, message_id);
            break;
          case "fund_req_100":
            await handleFundingRequest(chat_id, 100, 2500);
            break;
          case "fund_req_200":
            await handleFundingRequest(chat_id, 200, 4500);
            break;
          case "fund_req_500":
            await handleFundingRequest(chat_id, 500, 10000);
            break;
          case "collect_points":
            await handleCollectPoints(chat_id, message_id);
            break;
          case "agents":
            await handleAgents(chat_id, message_id);
            break;
          case "history":
            await handleHistory(chat_id, message_id, 0);
            break;
          case "history_next": {
            // We use callback data like history_next_10
            const nextOffset = parseInt(data.split("_")[2]) || 0;
            await handleHistory(chat_id, message_id, nextOffset);
            break;
          }
          case "daily_tasks":
            await handleDailyTasks(chat_id, message_id);
            break;
          case "verify_ss_youtube":
            await startScreenshotTask(chat_id, "youtube");
            break;
          case "verify_gift_task":
            await verifyRealGiftTask(chat_id);
            break;
          case "verify_event_task":
            await verifyRealEventTask(chat_id);
            break;
          case "verify_ss_tiktok":
            await startScreenshotTask(chat_id, "tiktok");
            break;
          case "verify_ss_facebook":
            await startScreenshotTask(chat_id, "facebook");
            break;
          case "create_agency":
            await handleCreateAgencyStart(chat_id);
            break;
          case "join_agency":
            await handleJoinAgencyList(chat_id, message_id);
            break;
          case "join_family":
            await handleJoinFamilyList(chat_id, message_id);
            break;
          case "create_family_start":
            await handleCreateFamilyStart(chat_id);
            break;
          case "back_to_menu":
            await handleStartCommand(chat_id, cb.from);
            break;
          case "coupons":
            await handleCoupons(chat_id, message_id);
            break;
          case "view_coupon_bronze":
            await handleViewCouponCard(chat_id, message_id, "bronze");
            break;
          case "view_coupon_silver":
            await handleViewCouponCard(chat_id, message_id, "silver");
            break;
          case "view_coupon_gold":
            await handleViewCouponCard(chat_id, message_id, "gold");
            break;
          default:
            await handleSpecialCallbacks(chat_id, data);
            break;
        }

        // Answer callback
        // Already answered above
      }

      res.status(200).send("OK");
    } catch (error: any) {
      console.error("Critical Bot Error:", error?.response?.data || error.message);
      // Always respond with 200 OK to Telegram to prevent retry loops and webhook disabling
      if (!res.headersSent) {
        res.status(200).send("OK");
      }
    }
  });

/**
 * ⚙ Handle Callback Actions
 */
async function handleSpecialCallbacks(chat_id: number, data: string) {
  if (data.startsWith("view_p_")) {
    const targetId = data.replace("view_p_", "");
    await handleViewPublicProfile(chat_id, targetId);
  }
  else if (data.startsWith("verify_p_")) {
    const requestId = data.replace("verify_p_", "");
    await verifyPromotedJoin(chat_id, requestId);
  }
  else if (data.startsWith("join_ag_")) {
    const agencyId = data.replace("join_ag_", "");
    await handleJoinAgency(chat_id, agencyId);
  }
  else if (data.startsWith("view_fam_")) {
    const familyId = data.replace("view_fam_", "");
    await handleViewFamily(chat_id, familyId);
  }
  else if (data.startsWith("join_fam_exec_")) {
    const familyId = data.replace("join_fam_exec_", "");
    await handleJoinFamilyExecute(chat_id, familyId);
  }
  else if (data.startsWith("buy_id_")) {
    const docId = data.replace("buy_id_", "");
    await handleBuyID(chat_id, docId);
  }
  else if (data.startsWith("claim_coupon_")) {
    const type = data.replace("claim_coupon_", "");
    await handleClaimCoupon(chat_id, type);
  }
  else if (data.startsWith("approve_ss_")) {
    const [_, __, type, userId] = data.split("_");
    await handleAdminApproveSS(chat_id, userId, type);
  }
}

/**
 * 👑 Admin Panel Handler
 */
async function handleAdminPanel(chat_id: number, message_id: number) {
  const text = `👑 <b>لوحة تحكم المدير</b> 👑

أهلاً بك يا سيدي. من هنا يمكنك إدارة النظام بالكامل ونشر المحتوى للمركز الإعلامي وإدارة اشتراكات VIP.`;

  const keyboard = {
    inline_keyboard: [
      [
        { text: "💰 شحن نقاط لمستخدم", callback_data: "admin_charge_points" },
        { text: "💸 خصم نقاط من مستخدم", callback_data: "admin_deduct_points" }
      ],
      [{ text: "📢 إرسال رسالة جماعية (Broadcast)", callback_data: "admin_broadcast" }],
      [
        { text: "📰 نشر خبر جديد", callback_data: "admin_create_news" },
        { text: "🎉 إنشاء عرض حصري", callback_data: "admin_create_offer" }
      ],
      [
        { text: "📢 تمويل قناة إداري", callback_data: "admin_promo_fund" },
        { text: "📊 إحصائيات النظام", callback_data: "admin_system_stats" }
      ],
      [
        { text: "👥 مستخدمو البوت", callback_data: "admin_bot_users" },
        { text: "🏆 إنشاء مسابقة جديدة", callback_data: "admin_create_contest" }
      ],
      [
        { text: "💎 إنشاء باقة VIP", callback_data: "admin_create_vip" }
      ],
      [{ text: "⬅️ الرجوع للقائمة الرئيسية", callback_data: "back_to_menu" }],
    ],
  };

  await editMessage(chat_id, message_id, text, keyboard);
}

/**
 * � Show Bot Users and Telegram Profile Links
 */
async function handleAdminBotUsers(chat_id: number, message_id: number) {
  try {
    const usersSnapshot = await db.collection("telegram_users").get();
    const users = usersSnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })) as any[];
    const total = usersSnapshot.size;

    let text = `👥 <b>مستخدمو البوت</b> 👥\n\n`;
    text += `• عدد مستخدمي البوت: <code>${total}</code>\n`;
    text += `• يتم حفظ معلومات كل مستخدم عند انضمامه للبوت.\n\n`;
    text += `اضغط على اسم المستخدم لفتح صفحته في التلغرام:`;

    const buttons: any[] = [];
    let shown = 0;
    for (const user of users) {
      if (shown >= 5) break;
      const username = user.username;
      const name = user.first_name || `مستخدم ${user.id}`;
      if (username && username !== "Unknown") {
        const safeUsername = username.replace(/^@/, "");
        buttons.push([{ text: `${name}`, url: `https://t.me/${safeUsername}` }]);
        shown += 1;
      }
    }

    if (shown === 0) {
      text += `\n\nلا يوجد مستخدمين لديهم اسم مستخدم Telegram مرتبطة بعد.`;
    }

    const keyboard = {
      inline_keyboard: [
        ...buttons,
        [{ text: "⬅️ الرجوع للوحة الإدارة", callback_data: "admin_panel" }]
      ]
    };

    await editMessage(chat_id, message_id, text, keyboard);
  } catch (error) {
    console.error("Admin Bot Users Error:", error);
    await editMessage(chat_id, message_id, "❌ حدث خطأ أثناء جلب بيانات مستخدمي البوت.", {
      inline_keyboard: [[{ text: "⬅️ الرجوع للوحة الإدارة", callback_data: "admin_panel" }]]
    });
  }
}

/**
 * �💰 Step 1: Ask for Target User ID
 */
async function askForTargetUserId(chat_id: number, action: "charge" | "deduct") {
  const state = action === "charge" ? "waiting_for_target_id" : "waiting_for_deduct_target_id";

  await db.collection("telegram_users").doc(chat_id.toString()).update({
    admin_state: state
  });

  const actionText = action === "charge" ? "شحنه" : "الخصم منه";
  await sendMessage(chat_id, `👤 **يرجى إرسال ID التلغرام الخاص بالمستخدم المراد ${actionText}:**\n\n(مثال: 123456789)`);
}

/**
 * 📢 Handle Broadcast Logic
 */
async function askForBroadcastMessage(chat_id: number) {
  await db.collection("telegram_users").doc(chat_id.toString()).update({
    admin_state: "waiting_for_broadcast_msg"
  });

  await sendMessage(chat_id, "📢 **يرجى كتابة الرسالة المراد إرسالها لجميع مستخدمي البوت:**\n\n(يمكنك إرسال نص أو روابط)");
}

/**
 * 📢 Ask for Promo Link (Admin)
 */
async function askForPromoLink(chat_id: number) {
  await db.collection("telegram_users").doc(chat_id.toString()).update({
    admin_state: "waiting_for_promo_link"
  });

  await sendMessage(chat_id, "📢 <b>إضافة قناة/مجموعة للتمويل الإداري</b>\n\nيرجى إرسال رابط القناة أو المجموعة (مثل: https://t.me/royaldoor)\n\nستظهر فوراً في قسم 'تجميع النقاط' وسيحصل المستخدمون على 5 نقاط عند الاشتراك.");
}

/**
 * ✅ Process Admin Promotion
 */
async function processAdminPromo(adminId: number, link: string) {
  try {
    await db.collection("funding_requests").add({
      userId: adminId,
      channelLink: link,
      membersCount: 999999, // Admin promo is "infinite" or very large
      costPoints: 0,
      status: "processing", // Make it show up in promoted_list
      isAdminPromo: true,
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });

    await sendMessage(adminId, "✅ <b>تم تفعيل التمويل بنجاح!</b>\n\nالقناة الآن تظهر لجميع المستخدمين في قسم تجميع النقاط.");
  } catch (error) {
    console.error("Admin Promo Error:", error);
    await sendMessage(adminId, "❌ حدث خطأ أثناء تفعيل التمويل.");
  }
}

/**
 * 📢 Handle Exclusive Offers List
 */
async function handleOffers(chat_id: number, message_id: number) {
  try {
    console.log(`Fetching offers for ${chat_id}`);
    const snapshot = await db.collection("royal_offers")
      .where("isActive", "==", true)
      .limit(10)
      .get();

    let text = `🎉 <b>العروض الحصرية الملكية</b> 🎉\n\n`;

    if (snapshot.empty) {
      text += "✨ لا توجد عروض نشطة حالياً. انتظرنا قريباً!";
    } else {
      // Sort manually if createdAt is missing in some docs to avoid index issues
      const docs = snapshot.docs.sort((a, b) => {
        const timeA = a.data().createdAt?.toMillis() || 0;
        const timeB = b.data().createdAt?.toMillis() || 0;
        return timeB - timeA;
      });

      docs.forEach((doc, index) => {
        const data = doc.data();
        text += `🔥 <b>العرض ${index + 1}: ${escapeHTML(data.title)}</b>\n`;
        text += `📝 ${escapeHTML(data.description)}\n`;
        if (data.price) text += `💰 السعر: <code>${escapeHTML(data.price.toString())}</code> نقطة\n`;
        text += `━━━━━━━━━━━━\n\n`;
      });
    }

    const keyboard = {
      inline_keyboard: [[{ text: "⬅️ الرجوع للمركز الإعلامي", callback_data: "media_center_menu" }]],
    };

    await editMessage(chat_id, message_id, text, keyboard);
  } catch (error: any) {
    console.error("Offers Error:", error);
    await editMessage(chat_id, message_id, `❌ عذراً، تعذر جلب قائمة العروض حالياً.\n\nخطأ: ${escapeHTML(error.message)}`);
  }
}

/**
 * 🆔 Handle Royal IDs (Marketplace IDs)
 */
async function handleRoyalIDs(chat_id: number, message_id: number) {
  try {
    console.log(`Fetching Royal IDs for ${chat_id}`);
    const snapshot = await db.collection("special_ids")
      .where("isSold", "==", false)
      .where("showInStore", "==", true)
      .limit(10)
      .get();

    let text = `🆔 <b>متجر الأيديات الملكية</b> 🆔\n\n`;
    text += `تميز بآيدي رسمي وحقيقي داخل التطبيق! ✨\n\n`;
    text += `💰 <b>سعر الشحن:</b> 10,000 نقطة = 10,000 دينار عراقي\n`;
    text += `🔄 <b>معدل التحويل:</b> 100 نقطة = 10 جواهر\n\n`;

    const buttons: any[] = [];

    if (snapshot.empty) {
      text += "✨ لا توجد أيديات متاحة حالياً. تابعنا للمزيد!";
    } else {
      // Sort manually by price
      const docs = snapshot.docs.sort((a, b) => (a.data().price || 0) - (b.data().price || 0));

      docs.forEach((doc, index) => {
        const data = doc.data();
        const royalId = data.royalId || data.value || "Unknown";
        let originalPrice = data.price || 0;

        // Convert to points: 10 points per 1 gem
        // If it's coins, we assume 1 gem = 2 coins or similar, but user specifically mentioned gems.
        // Let's assume the stored price is in Gems for these special IDs.
        let priceInPoints = originalPrice * 10;

        text += `${index + 1}️⃣ <b>ID:</b> <code>${escapeHTML(royalId)}</code>\n💰 السعر: <b>${priceInPoints.toLocaleString()}</b> نقطة\n\n`;
        buttons.push([{ text: `🛒 شراء الأيدي: ${royalId}`, callback_data: `buy_id_${doc.id}` }]);
      });
    }

    const keyboard = {
      inline_keyboard: [
        ...buttons,
        [{ text: "⬅️ الرجوع", callback_data: "back_to_menu" }],
      ],
    };

    await editMessage(chat_id, message_id, text, keyboard);
  } catch (error: any) {
    console.error("Royal IDs Error:", error);
    await editMessage(chat_id, message_id, `❌ عذراً، تعذر جلب قائمة الأيديات حالياً.\n\nخطأ: ${escapeHTML(error.message)}`);
  }
}

/**
 * 🛠 Handle Buy ID Logic
 */
async function handleBuyID(chat_id: number, docId: string) {
  const userRef = db.collection("telegram_users").doc(chat_id.toString());
  const userDoc = await userRef.get();
  const userData = userDoc.data();
  const appUid = userData?.app_uid;

  if (!appUid) {
    await sendMessage(chat_id, "❌ **يجب ربط حسابك بالتطبيق أولاً** لتتمكن من شراء آيدي رسمي.");
    return;
  }

  const specialDocRef = db.collection("special_ids").doc(docId);
  const specialDoc = await specialDocRef.get();

  if (!specialDoc.exists || specialDoc.data()?.isSold) {
    await sendMessage(chat_id, "❌ عذراً، هذا الأيدي لم يعد متاحاً.");
    return;
  }

  const data = specialDoc.data()!;
  const originalPrice = data.price || 0;
  const priceInPoints = originalPrice * 10; // 10 points per 1 gem
  const royalIdValue = data.royalId || data.value;

  try {
    await db.runTransaction(async (transaction) => {
      // 1. Check Bot Points Balance
      const currentPoints = userData?.points || 0;

      if (currentPoints < priceInPoints) {
        throw new Error("Insufficient points balance");
      }

      // 2. Deduct points from Telegram User
      transaction.update(userRef, {
        points: admin.firestore.FieldValue.increment(-priceInPoints)
      });

      // 3. Update App User (grant ID)
      const appUserRef = db.collection("users").doc(appUid);
      transaction.update(appUserRef, {
        royalId: royalIdValue,
        shortId: royalIdValue,
        hasCustomId: true
      });

      // 4. Mark ID as sold
      transaction.update(specialDocRef, {
        isSold: true,
        ownerUid: appUid,
        soldAt: admin.firestore.FieldValue.serverTimestamp()
      });

      // 5. Log history in Bot
      const logRef = userRef.collection("history").doc();
      transaction.set(logRef, {
        type: "buy_royal_id",
        royalId: royalIdValue,
        pointsDeducted: priceInPoints,
        timestamp: admin.firestore.FieldValue.serverTimestamp()
      });
    });

    await sendMessage(chat_id, `✅ **مبروك! تم شراء الأيدي (${royalIdValue}) بنجاح!** 🎊\n\nتم خصم <code>${priceInPoints}</code> نقطة من رصيدك وتحديث هويتك في التطبيق فوراً. استمتع بهويتك الملكية الجديدة! ✨`);
  } catch (error: any) {
    if (error.message === "Insufficient points balance") {
      await sendMessage(chat_id, `❌ **نقاطك غير كافية!**\nتحتاج إلى <code>${priceInPoints}</code> نقطة لشراء هذا الأيدي. رصيدك الحالي: <code>${userData?.points || 0}</code> نقطة.`);
    } else {
      console.error("Buy ID Error:", error);
      await sendMessage(chat_id, "❌ حدث خطأ أثناء عملية الشراء. حاول مرة أخرى لاحقاً.");
    }
  }
}

/**
 * 🏆 Handle Contests List
 */
async function handleContests(chat_id: number, message_id: number) {
  try {
    console.log(`Fetching contests for ${chat_id}`);
    const snapshot = await db.collection("royal_contests")
      .where("isActive", "==", true)
      .limit(10)
      .get();

    let text = `🏆 <b>المسابقات والجوائز الملكية</b> 🏆\n\n`;

    if (snapshot.empty) {
      text += "✨ لا توجد مسابقات نشطة حالياً. استعد للتحدي القادم!";
    } else {
      // Sort manually to avoid index dependency
      const docs = snapshot.docs.sort((a, b) => {
        const timeA = a.data().createdAt?.toMillis() || 0;
        const timeB = b.data().createdAt?.toMillis() || 0;
        return timeB - timeA;
      });

      docs.forEach((doc, index) => {
        const data = doc.data();
        text += `⭐ <b>مسابقة: ${escapeHTML(data.title)}</b>\n`;
        text += `🎁 الجائزة: <code>${escapeHTML(data.prize)}</code>\n`;
        text += `📋 الشروط: ${escapeHTML(data.rules)}\n`;
        text += `━━━━━━━━━━━━\n\n`;
      });
    }

    const keyboard = {
      inline_keyboard: [[{ text: "⬅️ الرجوع للمركز الإعلامي", callback_data: "media_center_menu" }]],
    };

    await editMessage(chat_id, message_id, text, keyboard);
  } catch (error: any) {
    console.error("Contests Error:", error);
    await editMessage(chat_id, message_id, `❌ عذراً، تعذر جلب قائمة المسابقات.\n\nخطأ: ${escapeHTML(error.message)}`);
  }
}

/**
 * 🛠 Admin Creation Initiation
 */
async function startAdminCreation(chat_id: number, type: "news" | "offer" | "contest" | "vip") {
  await db.collection("telegram_users").doc(chat_id.toString()).update({
    admin_state: `waiting_for_${type}_title`
  });

  const titles: any = { news: "الخبر", offer: "العرض", contest: "المسابقة", vip: "باقة VIP" };
  await sendMessage(chat_id, `📝 **بدء إنشاء ${titles[type]} جديد**\n\nيرجى إرسال **العنوان/الاسم**:`);
}

/**
 * 👑 Admin Approve Screenshot
 */
async function handleAdminApproveSS(adminId: number, targetUserId: string, type: string) {
  try {
    const pointsMap: any = { youtube: 3, tiktok: 10, facebook: 10 };
    const points = pointsMap[type] || 5;

    const userRef = db.collection("telegram_users").doc(targetUserId);
    await userRef.update({
      points: admin.firestore.FieldValue.increment(points),
      completed_tasks: admin.firestore.FieldValue.arrayUnion(`ss_${type}`)
    });

    await sendMessage(adminId, `✅ تم الموافقة على الصورة ومنح ${points} نقاط للمستخدم <code>${targetUserId}</code>`);
    await sendMessage(parseInt(targetUserId), `🎉 <b>مبروك!</b> وافقت الإدارة على إثبات ${type} الخاص بك. تم إضافة ${points} نقاط لرصيدك.`);
  } catch (error) {
    console.error("Approve SS Error:", error);
  }
}
async function handleSystemStats(chat_id: number, message_id: number) {
  try {
    const usersSnapshot = await db.collection("telegram_users").get();
    const appUsersSnapshot = await db.collection("users").get();
    const fundingSnapshot = await db.collection("funding_requests").get();

    let totalPoints = 0;
    usersSnapshot.forEach(doc => {
      totalPoints += (doc.data().points || 0);
    });

    const text = `📊 **إحصائيات النظام العامة** 📊

👥 **المستخدمون:**
• مستخدمو البوت: \`${usersSnapshot.size}\`
• مستخدمو التطبيق: \`${appUsersSnapshot.size}\`

💰 **المالية:**
• إجمالي النقاط المتداولة: \`${totalPoints}\`

📢 **الخدمات:**
• طلبات التمويل الكلية: \`${fundingSnapshot.size}\`

✨ *النظام يعمل بكفاءة تامة*`;

    const keyboard = {
      inline_keyboard: [
        [{ text: "⬅️ الرجوع للوحة الإدارة", callback_data: "admin_panel" }],
      ],
    };

    await editMessage(chat_id, message_id, text, keyboard);
  } catch (error) {
    console.error("System Stats Error:", error);
  }
}

/**
 * ⚙️ Handle Admin Sequential Inputs
 */
async function handleAdminInputs(chat_id: number, text: string, state: string, photo?: any[]) {
  const adminRef = db.collection("telegram_users").doc(chat_id.toString());
  const adminData = (await adminRef.get()).data();

  // Charge Points Flow
  if (state === "waiting_for_target_id") {
    const targetId = text.trim();
    const targetDoc = await db.collection("telegram_users").doc(targetId).get();
    if (!targetDoc.exists) {
      await sendMessage(chat_id, "❌ الـ ID غير موجود!");
      return;
    }
    await adminRef.update({ admin_state: "waiting_for_points_amount", admin_target_id: targetId });
    await sendMessage(chat_id, `✅ تم اختيار: ${targetDoc.data()?.first_name}\n\nأدخل عدد النقاط المراد شحنها:`);
  }
  else if (state === "waiting_for_points_amount") {
    const points = parseInt(text.trim());
    if (isNaN(points) || points <= 0) return;
    await chargeUserPoints(chat_id, adminData?.admin_target_id, points);
    await adminRef.update({ admin_state: admin.firestore.FieldValue.delete(), admin_target_id: admin.firestore.FieldValue.delete() });
  }

  // Deduct Points Flow
  else if (state === "waiting_for_deduct_target_id") {
    const targetId = text.trim();
    const targetDoc = await db.collection("telegram_users").doc(targetId).get();
    if (!targetDoc.exists) {
      await sendMessage(chat_id, "❌ الـ ID غير موجود!");
      return;
    }
    await adminRef.update({ admin_state: "waiting_for_deduct_amount", admin_target_id: targetId });
    await sendMessage(chat_id, `✅ تم اختيار: ${targetDoc.data()?.first_name}\n\nأدخل عدد النقاط المراد **خصمها**:`);
  }
  else if (state === "waiting_for_deduct_amount") {
    const points = parseInt(text.trim());
    if (isNaN(points) || points <= 0) return;
    await deductUserPoints(chat_id, adminData?.admin_target_id, points);
    await adminRef.update({ admin_state: admin.firestore.FieldValue.delete(), admin_target_id: admin.firestore.FieldValue.delete() });
  }

  // Broadcast Flow
  else if (state === "waiting_for_broadcast_msg") {
    await adminRef.update({ admin_state: admin.firestore.FieldValue.delete() });
    await processBroadcast(chat_id, text);
  }

  // Admin Promo Flow
  else if (state === "waiting_for_promo_link") {
    await adminRef.update({ admin_state: admin.firestore.FieldValue.delete() });
    await processAdminPromo(chat_id, text);
  }

  // Generic Media Creation Flows
  else if (state.endsWith("_title")) {
    const type = state.split("_")[2];
    await adminRef.update({ admin_state: `waiting_for_${type}_desc`, temp_title: text });
    if (type === "vip") {
      await sendMessage(chat_id, "✅ العنوان محفوظ. الآن أرسل <b>مميزات الباقة</b>:");
    } else {
      await sendMessage(chat_id, "✅ العنوان محفوظ. الآن أرسل <b>الوصف/التفاصيل</b>: ");
    }
  }
  else if (state.endsWith("_desc")) {
    const type = state.split("_")[2];
    if (type === "offer") {
      await adminRef.update({ admin_state: "waiting_for_offer_price", temp_desc: text });
      await sendMessage(chat_id, "✅ الوصف محفوظ. أرسل الآن <b>سعر العرض</b> (بالنقاط):");
    } else if (type === "contest") {
      await adminRef.update({ admin_state: "waiting_for_contest_prize", temp_desc: text });
      await sendMessage(chat_id, "✅ التفاصيل محفوظة. أرسل الآن <b>الجائزة</b>: ");
    } else if (type === "vip") {
      await adminRef.update({ admin_state: "waiting_for_vip_photo", temp_desc: text });
      await sendMessage(chat_id, "✅ المميزات محفوظة. أرسل الآن <b>صورة الباقة</b> (أو أرسل 'لا' لتخطي الصورة):");
    } else {
      // It's News, finish here
      await db.collection("system_announcements").add({
        title: adminData?.temp_title,
        content: text,
        isActive: true,
        createdAt: admin.firestore.FieldValue.serverTimestamp()
      });
      await adminRef.update({ admin_state: admin.firestore.FieldValue.delete(), temp_title: admin.firestore.FieldValue.delete() });
      await sendMessage(chat_id, "✅ <b>تم نشر الخبر بنجاح وتزامن مع التطبيق!</b> 📰");
    }
  }
  else if (state === "waiting_for_vip_photo") {
    if (photo && photo.length > 0) {
      const fileId = photo[photo.length - 1].file_id;
      await adminRef.update({ admin_state: "waiting_for_vip_price", temp_photo: fileId });
      await sendMessage(chat_id, "✅ الصورة محفوظة. أرسل الآن <b>سعر الاشتراك</b> (بالجواهر):");
    } else {
      await adminRef.update({ admin_state: "waiting_for_vip_price" });
      await sendMessage(chat_id, "✅ تم تخطي الصورة. أرسل الآن <b>سعر الاشتراك</b> (بالجواهر):");
    }
  }
  else if (state === "waiting_for_offer_price") {
    await db.collection("royal_offers").add({
      title: adminData?.temp_title,
      description: adminData?.temp_desc,
      price: text,
      isActive: true,
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });
    await adminRef.update({ admin_state: admin.firestore.FieldValue.delete(), temp_title: admin.firestore.FieldValue.delete(), temp_desc: admin.firestore.FieldValue.delete() });
    await sendMessage(chat_id, "✅ <b>تم إنشاء العرض الحصري بنجاح!</b> 🎉");
  }
  else if (state === "waiting_for_vip_price") {
    await db.collection("vip_packages").add({
      name: adminData?.temp_title,
      description: adminData?.temp_desc,
      photoUrl: adminData?.temp_photo || null,
      price: parseInt(text),
      currency: "gems",
      durationDays: 90, // App uses 90 days
      isActive: true,
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });
    await adminRef.update({
      admin_state: admin.firestore.FieldValue.delete(),
      temp_title: admin.firestore.FieldValue.delete(),
      temp_desc: admin.firestore.FieldValue.delete(),
      temp_photo: admin.firestore.FieldValue.delete()
    });
    await sendMessage(chat_id, "✅ <b>تم إنشاء باقة VIP بنجاح وتفعيلها في المتجر!</b> 💎");
  }
  else if (state === "waiting_for_contest_prize") {
    await adminRef.update({ admin_state: "waiting_for_contest_rules", temp_prize: text });
    await sendMessage(chat_id, "✅ الجائزة محفوظة. أرسل الآن **شروط المسابقة**: ");
  }
  else if (state === "waiting_for_contest_rules") {
    await db.collection("royal_contests").add({
      title: adminData?.temp_title,
      prize: adminData?.temp_prize,
      rules: text,
      isActive: true,
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });
    await adminRef.update({
      admin_state: admin.firestore.FieldValue.delete(),
      temp_title: admin.firestore.FieldValue.delete(),
      temp_prize: admin.firestore.FieldValue.delete()
    });
    await sendMessage(chat_id, "✅ **تم إنشاء المسابقة بنجاح!** 🏆");
  }
}

/**
 * 🚀 Process Broadcast Message
 */
async function processBroadcast(adminId: number, message: string) {
  await sendMessage(adminId, "⏳ جارِ إرسال الرسالة الجماعية... قد يستغرق هذا بعض الوقت.");

  try {
    const usersSnapshot = await db.collection("telegram_users").get();
    let successCount = 0;
    let failCount = 0;
    let errorDetail = "";

    for (const doc of usersSnapshot.docs) {
      const data = doc.data();
      const userId = data.telegram_id || parseInt(doc.id);

      if (!userId || isNaN(userId)) continue;

      try {
        await axios.post(`${TELEGRAM_API}/sendMessage`, {
          chat_id: userId,
          text: message,
          parse_mode: "HTML" // Using HTML as it's more stable for general text
        });
        successCount++;
      } catch (e: any) {
        failCount++;
        errorDetail = e.response?.data?.description || e.message;
      }
    }

    let report = `✅ **اكتمل الإرسال الجماعي!**\n\n تم الإرسال لـ \`${successCount}\` مستخدم.\n فشل الإرسال لـ \`${failCount}\`.`;
    if (failCount > 0) {
      report += `\n\n💡 *سبب الفشل غالباً:* المستخدم حظر البوت أو خطأ في تنسيق الرسالة.\n(آخر خطأ: \`${errorDetail}\`)`;
    }

    await sendMessage(adminId, report);
  } catch (err) {
    console.error("Broadcast Error:", err);
    await sendMessage(adminId, "❌ حدث خطأ جسيم أثناء الإرسال الجماعي.");
  }
}

/**
 * ✅ Process Real Charging
 */
async function chargeUserPoints(adminId: number, targetId: string, amount: number) {
  const targetRef = db.collection("telegram_users").doc(targetId);

  try {
    await db.runTransaction(async (transaction) => {
      // Add points to user
      transaction.update(targetRef, {
        points: admin.firestore.FieldValue.increment(amount),
        collective_points: admin.firestore.FieldValue.increment(amount)
      });

      // Log for admin
      const adminLogRef = db.collection("telegram_users").doc(adminId.toString()).collection("history").doc();
      transaction.set(adminLogRef, {
        type: "admin_charge",
        targetUserId: targetId,
        amount: amount,
        timestamp: admin.firestore.FieldValue.serverTimestamp()
      });

      // Log for user
      const userLogRef = targetRef.collection("history").doc();
      transaction.set(userLogRef, {
        type: "received_from_admin",
        amount: amount,
        timestamp: admin.firestore.FieldValue.serverTimestamp()
      });
    });

    // Notify Admin
    await sendMessage(adminId, `✅ **تم شحن \`${amount}\` نقطة للمستخدم (ID: ${targetId}) بنجاح!**`);

    // Notify User
    await sendMessage(parseInt(targetId), `🎁 **تهانينا!** لقد قامت الإدارة بشحن حسابك بـ \`${amount}\` نقطة ملكية. استمتع بها!`);

  } catch (error) {
    console.error("Admin Charge Error:", error);
    await sendMessage(adminId, "❌ حدث خطأ تقني أثناء عملية الشحن.");
  }
}

/**
 * 💸 Process Deducting Points
 */
async function deductUserPoints(adminId: number, targetId: string, amount: number) {
  const targetRef = db.collection("telegram_users").doc(targetId);

  try {
    const result = await db.runTransaction(async (transaction) => {
      const userDoc = await transaction.get(targetRef);
      if (!userDoc.exists) throw new Error("User not found");

      const currentPoints = userDoc.data()?.points || 0;
      if (currentPoints < amount) {
        throw new Error("Insufficient balance");
      }

      // Deduct points
      transaction.update(targetRef, {
        points: admin.firestore.FieldValue.increment(-amount)
      });

      // Log for admin
      const adminLogRef = db.collection("telegram_users").doc(adminId.toString()).collection("history").doc();
      transaction.set(adminLogRef, {
        type: "admin_deduct",
        targetUserId: targetId,
        amount: amount,
        timestamp: admin.firestore.FieldValue.serverTimestamp()
      });

      // Log for user
      const userLogRef = targetRef.collection("history").doc();
      transaction.set(userLogRef, {
        type: "deducted_by_admin",
        amount: amount,
        timestamp: admin.firestore.FieldValue.serverTimestamp()
      });

      return true;
    });

    if (result) {
      await sendMessage(adminId, `✅ <b>تم خصم <code>${amount}</code> نقطة بنجاح</b> من المستخدم (ID: ${targetId}).`);
      await sendMessage(parseInt(targetId), `💸 <b>تنبيه ملكي:</b> قامت الإدارة بخصم <code>${amount}</code> نقطة من رصيدك.`);
    }
  } catch (error: any) {
    if (error.message === "Insufficient balance") {
      await sendMessage(adminId, `❌ <b>فشل الخصم!</b> رصيد المستخدم لا يكفي لخصم هذا المبلغ.`);
    } else {
      console.error("Admin Deduct Error:", error);
      await sendMessage(adminId, "❌ حدث خطأ تقني أثناء عملية الخصم.");
    }
  }
}

/**
 * 🔗 Process Account Linking
 */
async function handleAccountLinking(chat_id: number, appUid: string, user: any) {
  try {
    const tgRef = db.collection("telegram_users").doc(chat_id.toString());
    const appRef = db.collection("users").doc(appUid);

    const appDoc = await appRef.get();
    if (!appDoc.exists) {
      await sendMessage(chat_id, "❌ **فشل الربط!** لم يتم العثور على حساب التطبيق المطلوب.");
      return;
    }

    await db.runTransaction(async (transaction) => {
      // 1. Update Telegram User
      transaction.set(tgRef, {
        app_uid: appUid,
        linked_at: admin.firestore.FieldValue.serverTimestamp(),
        // Also ensure user exists with basic info
        telegram_id: chat_id,
        first_name: user?.first_name || "Unknown",
        username: user?.username || "Unknown"
      }, { merge: true });

      // 2. Update App User
      transaction.update(appRef, {
        telegram_id: chat_id.toString(),
        telegram_linked: true,
        telegram_linked_at: admin.firestore.FieldValue.serverTimestamp()
      });
    });

    await sendMessage(chat_id, `✅ **تم ربط حسابك بنجاح!** 🎊\n\nأهلاً بك يا \`${appDoc.data()?.name}\` في الديوان الملكي للبوت. يمكنك الآن تحويل النقاط وإدارة استثماراتك بسهولة.`);
  } catch (error) {
    console.error("Linking Error:", error);
    await sendMessage(chat_id, "❌ حدث خطأ أثناء عملية ربط الحساب.");
  }
}

/**
 * 🚀 Process Referral Points (With Leave Protection)
 */
async function handleReferralPoints(newUserId: number, startParam: string) {
  try {
    const newUserRef = db.collection("telegram_users").doc(newUserId.toString());
    const newUserDoc = await newUserRef.get();

    // Only reward if it's a new user
    if (!newUserDoc.exists) {
      const isSocialMedia = startParam.startsWith("sm_");
      const referrerId = startParam.replace("tg_", "").replace("sm_", "");

      const referrerRef = db.collection("telegram_users").doc(referrerId);
      const referrerDoc = await referrerRef.get();

      if (referrerDoc.exists && referrerId !== newUserId.toString()) {
        const pointsToAdd = isSocialMedia ? 5 : 2;

        await referrerRef.update({
          points: admin.firestore.FieldValue.increment(pointsToAdd),
          referrals: admin.firestore.FieldValue.increment(1)
        });

        // Record the referral relationship for "Leave Protection"
        await db.collection("referral_tracking").doc(newUserId.toString()).set({
          referrerId: referrerId,
          pointsAwarded: pointsToAdd,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
          status: "active"
        });

        // Notify referrer
        const sourceName = isSocialMedia ? "السوشل ميديا" : "التلغرام";
        await sendMessage(parseInt(referrerId), `🎊 انضم مستخدم جديد عن طريق ${sourceName}! لقد حصلت على <b>${pointsToAdd}</b> نقطة ملكية.\n\n⚠️ <i>ملاحظة: سيتم خصم النقاط في حال غادر العضو خلال أول 24 ساعة.</i>`);
      }
    }
  } catch (error) {
    console.error("Referral Points Error:", error);
  }
}

/**
 * 👥 Deduct Points if Referral Leaves
 */
export async function handleUserLeave(newUserId: number) {
  try {
    const trackingRef = db.collection("referral_tracking").doc(newUserId.toString());
    const trackingDoc = await trackingRef.get();

    if (trackingDoc.exists && trackingDoc.data()?.status === "active") {
      const { referrerId, pointsAwarded } = trackingDoc.data()!;

      const referrerRef = db.collection("telegram_users").doc(referrerId);
      await referrerRef.update({
        points: admin.firestore.FieldValue.increment(-pointsAwarded),
        referrals: admin.firestore.FieldValue.increment(-1)
      });

      await trackingRef.update({ status: "left_and_deducted" });

      await sendMessage(parseInt(referrerId), `💸 <b>تنبيه:</b> غادر العضو الذي دعوته مسبقاً، ولذلك تم خصم <code>${pointsAwarded}</code> نقطة من رصيدك.`);
    }
  } catch (error) {
    console.error("Referral Deduction Error:", error);
  }
}

/**
 * 📱 Start Command - Main Menu
 */
/**
 * 📞 Handle Contact Message (Verification)
 */
async function handleContactMessage(chat_id: number, contact: any) {
  const phone = contact.phone_number;
  const contactUserId = contact.user_id;

  // 1. التحقق من أن جهة الاتصال تخص المستخدم نفسه
  if (contactUserId !== chat_id) {
    await axios.post(`${TELEGRAM_API}/sendMessage`, {
      chat_id,
      text: "⚠️ يرجى مشاركة رقم هاتفك الخاص من خلال الزر المخصص فقط.",
    });
    return;
  }

  // 2. فحص الأرقام الوهمية (قائمة سوداء لمقدمات الأرقام)
  // +1: USA/Canada, +371: Latvia, +44: UK (often virtual), +48: Poland (virtual)
  const blacklistedPrefixes = ["1", "371", "48"];
  const cleanPhone = phone.replace("+", "");

  const isBlacklisted = blacklistedPrefixes.some(prefix => cleanPhone.startsWith(prefix));

  if (isBlacklisted) {
    await axios.post(`${TELEGRAM_API}/sendMessage`, {
      chat_id,
      text: "❌ عذراً، لا يمكن استخدام أرقام الهواتف الوهمية أو الدولية غير المدعومة لتفعيل التطبيق.",
    });
    return;
  }

  // 3. تحديث حالة المستخدم في Firestore
  await db.collection("telegram_users").doc(chat_id.toString()).update({
    phone_verified: true,
    verified_phone: phone,
    verified_at: admin.firestore.FieldValue.serverTimestamp(),
  });

  await axios.post(`${TELEGRAM_API}/sendMessage`, {
    chat_id,
    text: "✅ تم التحقق من رقم هاتفك بنجاح! يمكنك الآن استخدام التطبيق وكافة الخدمات.",
    reply_markup: {
      remove_keyboard: true // إخفاء لوحة مفاتيح طلب الرقم
    }
  });

  // إعادة إظهار قائمة البداية مع زر التطبيق
  const userDoc = await db.collection("telegram_users").doc(chat_id.toString()).get();
  await handleStartCommand(chat_id, userDoc.data());
}

async function handleStartCommand(chat_id: number, user: any) {
  const firstName = user?.first_name || "عزيزي";
  // Added multiple admin IDs for testing and provided by user
  const adminIds = ["8395753074", "8891534373", "7770992966", "123456789"];
  const isAdmin = adminIds.includes(chat_id.toString());

  console.log(`User ${chat_id} (isAdmin: ${isAdmin}) started the bot`);
  const userRef = db.collection("telegram_users").doc(chat_id.toString());
  let userDoc = await userRef.get();

  if (!userDoc.exists) {
    await userRef.set({
      telegram_id: chat_id,
      first_name: firstName,
      username: user?.username || "Unknown",
      last_name: user?.last_name || "",
      joined_at: admin.firestore.FieldValue.serverTimestamp(),
      points: 0,
      level: 1,
      referrals: 0,
      is_vip: false,
      completed_tasks: []
    }, { merge: true });
    userDoc = await userRef.get();
  }

  const userData = userDoc.data();
  const isPhoneVerified = userData?.phone_verified === true;
  const userBalance = userData?.points || 0;
  const totalTransfers = userData?.transfers_count || 0;
  const collectivePoints = userData?.collective_points || 0;
  const vipLevel = userData?.is_vip ? (userData?.vip_type === "platinum" ? "بلاتيني 💎" : "VIP الملكي ⭐") : "عضو عادي";

  // Calculate Real Daily Reward from App Investment Packages
  let realDailyReward = 0;
  if (userData?.app_uid) {
    const rewardsSnapshot = await db.collection("users").doc(userData.app_uid).collection("active_rewards").where("status", "==", "active").get();
    rewardsSnapshot.forEach(doc => {
      realDailyReward += (doc.data().dailyReward || 0);
    });
  }
  // Base bot daily reward if no app rewards
  const displayDaily = realDailyReward > 0 ? realDailyReward.toFixed(0) : "2";

  const welcomeText = `👑 **مرحباً بك ${firstName} في RoyalDoor** 👑

بوابتك الملكية لإدارة وتمويل:
✨ القنوات ✨ المجموعات ✨ الوكالات ✨ الحملات الإعلانية

اختر الخدمة المطلوبة من لوحة الأوامر بالأسفل، وسيتم تنفيذ طلبك خلال ثوانٍ.
نتمنى لك تجربة ملكية مميزة. 💚

━━━━━━━━━━━━
📊 **لوحة البيانات السريعة**
💰 الرصيد الحالي: \`${userBalance}\` نقطة
🎁 مكافأة اليوم: \`${displayDaily}\` نقطة
📈 إجمالي التحويلات: \`${totalTransfers}\`
🏆 نقاط المجمعة: \`${collectivePoints}\`
⭐ المستوى: \`${vipLevel}\`
━━━━━━━━━━━━`;

  const keyboard = {
    inline_keyboard: [
      // 👑 لوحة الإدارة (تظهر للمدير فقط)
      ...(isAdmin ? [[{ text: "👑 لوحة الإدارة (المدير)", callback_data: "admin_panel" }]] : []),

      // 👑 الخدمات الملكية + 📱 تطبيقي (فقط للمحققين)
      [
        { text: "👑 الخدمات الملكية", callback_data: "royal_services" },
        ...(isPhoneVerified
          ? [{ text: "📱 تطبيقي الملكي", web_app: { url: "https://royaldoor86-e6489.web.app" } }]
          : [{ text: "🛡️ تفعيل التطبيق", callback_data: "request_verification" }])
      ],

      // 👤 الحساب - دعوة صديق - التفاعل (بترتيب عربي من اليمين لليسار)
      [
        { text: "🚀 التفاعل", callback_data: "interaction_menu" },
        { text: "👥 دعوة صديق", callback_data: "referrals" },
        { text: "👤 الحساب", callback_data: "account_menu" }
      ],
      [
        { text: "📅 مهام يومية", callback_data: "daily_tasks" },
        { text: "📜 سجل العمليات", callback_data: "history" }
      ],

      // 🏛 وكالات RoyalDoor + 📰 المركز الإعلامي
      [
        { text: "📰 المركز الإعلامي", callback_data: "media_center_menu" },
        { text: "🏛 وكالات RoyalDoor", callback_data: "agencies_menu" }
      ],

      // الشريط السفلي السريع
      [
        { text: "📜 سجل", callback_data: "history" },
        { text: "🏆 ترتيب", callback_data: "leaderboard" },
        { text: "⚙ المساعدة", callback_data: "help_menu" },
        { text: "🆔 ايديات ID", callback_data: "royal_ids" }
      ],
      [
        { text: "🌐 الموقع", url: "https://www.royaldoor.live" },
        { text: "📊 إحصائيات", callback_data: "stats" },
        { text: "💎 VIP", callback_data: "vip" },
        { text: "🎫 كوبون", callback_data: "coupons" }
      ]
    ],
  };

  await sendMessage(chat_id, welcomeText, keyboard);
}

/**
 * 👑 Handle Royal Services
 */
async function handleRoyalServices(chat_id: number, message_id: number) {
  const text = `👑 **الخدمات الملكية**

بوابتك لتمويل وإدارة محتواك الإعلاني والتفاعلي.

اختر الخدمة المطلوبة:`;

  const keyboard = {
    inline_keyboard: [
      [{ text: "📢 تمويل قناة أو مجموعة", callback_data: "funding" }],
      [
        { text: "🔄 تحويل النقاط", callback_data: "treasury" },
        { text: "🎯 تجميع النقاط", callback_data: "collect_points" },
        { text: "💎 شراء النقاط", callback_data: "buy_points" }
      ],
      [{ text: "⬅️ الرجوع", callback_data: "back_to_menu" }],
    ],
  };

  await editMessage(chat_id, message_id, text, keyboard);
}

/**
 * 🎮 Handle Play Games
 */
async function handlePlayGames(chat_id: number, message_id: number) {
  const text = `🎮 **الالعاب والتحديات**

اختر اللعبة:`;

  const keyboard = {
    inline_keyboard: [
      [
        { text: "🎯 الأسئلة", callback_data: "game_quiz" },
        { text: "🎲 العجلة", callback_data: "game_wheel" },
      ],
      [
        { text: "🃏 الورق", callback_data: "game_cards" },
        { text: "🎰 الحظ", callback_data: "game_slots" },
      ],
      [{ text: "⬅️ الرجوع", callback_data: "back_to_menu" }],
    ],
  };

  await editMessage(chat_id, message_id, text, keyboard);
}

/**
 * 🏛 Handle Agencies Menu
 */
async function handleAgenciesMenu(chat_id: number, message_id: number) {
  const text = `🏛 **وكالات Royal Door** 🏛

أهلاً بك في قسم الوكالات. يمكنك هنا تأسيس وكالتك الخاصة أو الانضمام للوكلاء المعتمدين.

اختر الخدمة المطلوبة:`;

  const keyboard = {
    inline_keyboard: [
      [{ text: "👑 تأسيس وكالة", callback_data: "create_agency" }],
      [{ text: "🏰 وكلاء المحافظات", callback_data: "agents" }],
      [{ text: "🤝 الانضمام لوكالة", callback_data: "join_agency" }],
      [{ text: "👨‍👩‍👧‍👦 الانضمام لعائلة في التطبيق", callback_data: "join_family" }],
      [{ text: "⬅️ الرجوع للقائمة الرئيسية", callback_data: "back_to_menu" }],
    ],
  };

  await editMessage(chat_id, message_id, text, keyboard);
}

/**
 * 📰 Handle Media Center & News
 */
async function handleNews(chat_id: number, message_id: number) {
  try {
    // 1. Fetch Marquee Announcements (The "advertising bar" in the app)
    const marqueeDoc = await db.collection("settings").doc("marquee").get();
    const marqueeMessages = marqueeDoc.exists ? (marqueeDoc.data()?.messages as string[] || []) : [];

    // 2. Fetch System Announcements (News)
    const newsSnapshot = await db.collection("system_announcements")
      .orderBy("createdAt", "desc")
      .limit(5)
      .get();

    let text = `📰 <b>المركز الإعلامي - آخر الأخبار والإعلانات</b> 📰\n\n`;

    let counter = 1;

    // Display Marquee items first as they are the "advertising bar"
    if (marqueeMessages.length > 0) {
      text += `📢 <b>إعلانات شريط التطبيق:</b>\n`;
      marqueeMessages.forEach((msg) => {
        text += `✨ ${escapeHTML(msg)}\n`;
      });
      text += `━━━━━━━━━━━━\n\n`;
    }

    // Display News
    if (newsSnapshot.empty && marqueeMessages.length === 0) {
      text += "✨ لا توجد أخبار أو إعلانات نشطة حالياً. تابعنا للمزيد!";
    } else {
      if (!newsSnapshot.empty) {
        text += `📰 <b>أحدث الأخبار:</b>\n`;
        newsSnapshot.docs.forEach((doc) => {
          const data = doc.data();
          text += `${counter}️⃣ <b>${escapeHTML(data.title || "تنبيه ملكي")}</b>\n`;
          text += `${escapeHTML(data.content || "")}\n`;
          text += `📅 <i>${data.createdAt?.toDate().toLocaleDateString('ar-EG') || ""}</i>\n\n`;
          counter++;
        });
      }
    }

    const keyboard = {
      inline_keyboard: [
        [{ text: "🎉 العروض الحصرية", callback_data: "offers" }],
        [{ text: "🎁 المسابقات", callback_data: "contests" }],
        [{ text: "⬅️ الرجوع للقائمة الرئيسية", callback_data: "back_to_menu" }],
      ],
    };

    await editMessage(chat_id, message_id, text, keyboard);
  } catch (error) {
    console.error("News Fetch Error:", error);
    await editMessage(chat_id, message_id, "❌ عذراً، تعذر جلب الأخبار حالياً.");
  }
}

/**
 * ⭐ Handle VIP / Membership Levels
 */
async function handleVIP(chat_id: number, message_id: number) {
  try {
    const userDoc = await db.collection("telegram_users").doc(chat_id.toString()).get();
    const userData = userDoc.data();
    const currentLevel = userData?.is_vip ? (userData?.vip_type === "platinum" ? "بلاتيني 💎" : "VIP الملكي ⭐") : "عضو عادي";

    // Fetch VIP Packages from Firestore
    const vipSnapshot = await db.collection("vip_packages")
      .where("isActive", "==", true)
      .get();

    let text = `⭐ <b>الاشتراكات الملكية VIP</b> ⭐\n\n`;
    text += `عزز تجربتك واحصل على مميزات حصرية!\n\n`;
    text += `👤 <b>مستواك الحالي:</b> <code>${currentLevel}</code>\n\n`;

    const buttons: any[] = [];

    // Define app-matching packages if empty
    if (vipSnapshot.empty) {
      const packages = [
        { name: "الفيروز", price: "300,000", color: "💠", id: "turquoise", powers: ["شارة VIP", "إعلان دخول عالمي 📢", "توثيق الحساب ✅", "غرفه ملكيه 15 مايك"] },
        { name: "الزمرد", price: "400,000", color: "💚", id: "emerald", powers: ["درع الطرد 🛡️", "غرفه ملكيه 20 مايك", "سعة الأصدقاء 400", "زيادة المتابعة"] },
        { name: "اللؤلؤ", price: "500,000", color: "🤍", id: "pearl", powers: ["تأثير دخول فاخر", "غرفه ملكيه 25 مايك", "سعة الأصدقاء 700"] },
        { name: "الياقوت", price: "750,000", color: "🔴", id: "ruby", powers: ["درع الحصانة 🛡️", "أولوية المايك 🎤", "غرفه ملكيه 30 مايك"] },
        { name: "Royal Door", price: "1,000,000", color: "👑", id: "royal", powers: ["المستوى الملكي: 20 🏆", "آيدي ملكي مميز: 111111 🔥", "تجاوز قفل الغرف 🔐"] }
      ];

      packages.forEach(p => {
        text += `${p.color} <b>باقة ${p.name}:</b>\n`;
        text += `💰 السعر: <code>${p.price}</code> جوهرة\n`;
        text += `✨ المزايا: ${p.powers.join(", ")}...\n\n`;
        buttons.push([{ text: `🔓 تفعيل باقة ${p.name}`, callback_data: `buy_vip_${p.id}` }]);
      });
    } else {
      // Sort manually by price
      const docs = vipSnapshot.docs.sort((a, b) => (a.data().price || 0) - (b.data().price || 0));

      docs.forEach((doc) => {
        const data = doc.data();
        text += `✨ <b>باقة ${escapeHTML(data.name)}:</b>\n`;
        text += `💰 السعر: <code>${data.price}</code> ${data.currency === 'points' ? 'نقطة' : 'جوهرة'}\n`;
        if (data.description) text += `📜 المميزات: ${escapeHTML(data.description)}\n`;
        text += `\n`;
        buttons.push([{ text: `🔓 تفعيل باقة ${data.name}`, callback_data: `buy_vip_id_${doc.id}` }]);
      });
    }

    const keyboard = {
      inline_keyboard: [
        ...buttons,
        [{ text: "💎 شراء النقاط", callback_data: "buy_points" }],
        [{ text: "⬅️ الرجوع للحساب", callback_data: "account_menu" }],
      ],
    };

    await editMessage(chat_id, message_id, text, keyboard);
  } catch (error: any) {
    console.error("VIP Menu Error:", error);
    await editMessage(chat_id, message_id, `❌ تعذر جلب باقات VIP.\n\nخطأ: ${escapeHTML(error.message)}`);
  }
}

/**
 * 🔄 Handle Treasury (Points Conversion & Transfer)
 */
async function handleTreasury(chat_id: number, message_id: number) {
  const userDoc = await db.collection("telegram_users").doc(chat_id.toString()).get();
  const points = userDoc.data()?.points || 0;

  const text = `🔄 **المحجر الملكي - إدارة وتحويل النقاط** 🔄

رصيدك الحالي: \`${points}\` نقطة

اختر العملية المطلوبة:
💎 **تحويل للتطبيق:** حول نقاطك لمجوهرات أو كوينز داخل تطبيق رويال ريل.
🤝 **تحويل لصديق:** أرسل نقاطك لأي مستخدم آخر في البوت فوراً.`;

  const keyboard = {
    inline_keyboard: [
      [{ text: "🤝 تحويل نقاط إلى مستخدم آخر", callback_data: "transfer_to_user" }],
      [
        { text: "💎 تحويل لـ مجوهرات", callback_data: "convert_to_app_gems" },
        { text: "💰 تحويل لـ كوينز", callback_data: "convert_to_app_coins" }
      ],
      [{ text: "⬅️ الرجوع", callback_data: "back_to_menu" }],
    ],
  };

  await editMessage(chat_id, message_id, text, keyboard);
}

/**
 * 💎 Handle App Conversion Menus
 */
async function handleAppConversionMenu(chat_id: number, message_id: number, type: 'gems' | 'coins') {
  const name = type === 'gems' ? "مجوهرات 💎" : "كوينز 💰";
  const rate = type === 'gems' ? "10" : "20";

  const text = `🔄 **التحويل إلى ${name}** 🔄

سعر التحويل: 100 نقطة = ${rate} ${name}

اختر الكمية المراد تحويلها:`;

  const keyboard = {
    inline_keyboard: [
      [
        { text: `100 نقطة ⬅️ ${rate} ${name}`, callback_data: `convert_to_${type}_100` },
      ],
      [
        { text: `500 نقطة ⬅️ ${parseInt(rate)*5} ${name}`, callback_data: `convert_to_${type}_500` }
      ],
      [{ text: "⬅️ الرجوع للمحجر", callback_data: "treasury" }],
    ],
  };

  await editMessage(chat_id, message_id, text, keyboard);
}

/**
 * ⚙️ Handle Conversion Logic
 */
async function handleConversion(chat_id: number, pointsToDeduct: number, rewardAmount: number, rewardType: 'gems' | 'coins') {
  const tgUserRef = db.collection("telegram_users").doc(chat_id.toString());
  const tgUserDoc = await tgUserRef.get();
  const tgData = tgUserDoc.data();

  if (!tgData?.app_uid) {
    await sendMessage(chat_id, "❌ **فشل التحويل!** حسابك غير مرتبط بالتطبيق. يرجى ربط حسابك أولاً.");
    return;
  }

  const currentPoints = tgData.points || 0;
  if (currentPoints < pointsToDeduct) {
    await sendMessage(chat_id, `❌ **نقاطك غير كافية!** تحتاج إلى \`${pointsToDeduct}\` نقطة.`);
    return;
  }

  try {
    const appUid = tgData.app_uid;
    const appUserRef = db.collection("users").doc(appUid);

    await db.runTransaction(async (transaction) => {
      const appUserDoc = await transaction.get(appUserRef);
      if (!appUserDoc.exists) throw new Error("App user not found");

      // Deduct from Telegram
      transaction.update(tgUserRef, {
        points: admin.firestore.FieldValue.increment(-pointsToDeduct)
      });

      // Add to App Wallet
      const updateData: any = {};
      if (rewardType === 'gems') {
        updateData.gems = admin.firestore.FieldValue.increment(rewardAmount);
        updateData.rewardGems = admin.firestore.FieldValue.increment(rewardAmount);
      } else {
        updateData.coins = admin.firestore.FieldValue.increment(rewardAmount);
      }

      transaction.update(appUserRef, updateData);

      // Log transaction
      const logRef = tgUserRef.collection("history").doc();
      transaction.set(logRef, {
        type: "conversion",
        rewardType,
        pointsDeducted: pointsToDeduct,
        rewardReceived: rewardAmount,
        timestamp: admin.firestore.FieldValue.serverTimestamp()
      });
    });

    const rewardName = rewardType === 'gems' ? "جوهرة 💎" : "كوينز 💰";
    await sendMessage(chat_id, `✅ **تم التحويل بنجاح!**\n\nتم خصم \`${pointsToDeduct}\` نقطة وإضافة \`${rewardAmount}\` ${rewardName} إلى محفظتك في التطبيق.`);
  } catch (error) {
    console.error("Conversion Error:", error);
    await sendMessage(chat_id, "❌ حدث خطأ أثناء عملية التحويل. حاول مرة أخرى لاحقاً.");
  }
}

/**
 * 🤝 Step 1: Start User-to-User Transfer
 */
async function handleUserTransferStart(chat_id: number) {
  await db.collection("telegram_users").doc(chat_id.toString()).update({
    user_state: "waiting_for_transfer_target_id"
  });

  await sendMessage(chat_id, "👤 **يرجى إرسال ID التلغرام الخاص بصديقك:**\n\n(يمكن لصديقك الحصول على الـ ID الخاص به من صفحة معلومات الحساب في البوت)");
}

/**
 * 💎 Handle App Conversion (Start Process)
 */
async function handleAppConversionStart(chat_id: number, type: 'gems' | 'coins') {
  await db.collection("telegram_users").doc(chat_id.toString()).update({
    user_state: `waiting_for_app_id_${type}`
  });

  const name = type === 'gems' ? "مجوهرات 💎" : "كوينز 💰";
  await sendMessage(chat_id, `🔄 **بدء التحويل إلى ${name}** 🔄\n\nيرجى إرسال **رقم الآيدي (ID)** الخاص بك داخل تطبيق رويال ريل:`);
}

/**
 * ⚙️ Handle All User State Inputs (Transfer, Conversion, etc.)
 */
async function handleUserStateInputs(chat_id: number, text: string, state: string, photo?: any[]) {
  const userRef = db.collection("telegram_users").doc(chat_id.toString());
  const userDoc = await userRef.get();
  const userData = userDoc.data();

  // 1. User-to-User Transfer
  if (state === "waiting_for_transfer_target_id") {
    const targetId = text.trim();
    if (targetId === chat_id.toString()) {
      await sendMessage(chat_id, "❌ لا يمكنك تحويل النقاط لنفسك!");
      await userRef.update({ user_state: admin.firestore.FieldValue.delete() });
      return;
    }

    const targetDoc = await db.collection("telegram_users").doc(targetId).get();
    if (!targetDoc.exists) {
      await sendMessage(chat_id, "❌ **عذراً! هذا المستخدم غير مسجل في البوت.**\nيرجى التأكد من الـ ID.");
      return;
    }

    await userRef.update({
      user_state: "waiting_for_transfer_amount",
      transfer_target_id: targetId
    });

    await sendMessage(chat_id, `✅ **تم اختيار: ${targetDoc.data()?.first_name}**\n\nأدخل الآن **عدد النقاط** المراد تحويلها:`);
  }
  else if (state === "waiting_for_transfer_amount") {
    const amount = parseInt(text.trim());
    const targetId = userData?.transfer_target_id;

    if (isNaN(amount) || amount <= 0) {
      await sendMessage(chat_id, "❌ يرجى إدخال عدد نقاط صحيح.");
      return;
    }

    if ((userData?.points || 0) < amount) {
      await sendMessage(chat_id, `❌ **نقاطك غير كافية!**\nرصيدك الحالي: \`${userData?.points || 0}\` نقطة.`);
      return;
    }

    await executeUserTransfer(chat_id, targetId, amount);
    await userRef.update({ user_state: admin.firestore.FieldValue.delete(), transfer_target_id: admin.firestore.FieldValue.delete() });
  }

  // 2. Conversion to App (Gems/Coins)
  else if (state.startsWith("waiting_for_app_id_")) {
    const type = state.replace("waiting_for_app_id_", "") as 'gems' | 'coins';
    const appId = text.trim();

    // Verify App ID exists in users collection (by royalId or uid)
    const appUserQuery = await db.collection("users").where("royalId", "==", appId).limit(1).get();

    if (appUserQuery.empty) {
      await sendMessage(chat_id, "❌ **الآيدي غير صحيح!** لم يتم العثور على مستخدم بهذا الـ ID في التطبيق. يرجى التأكد وإعادة الإرسال:");
      return;
    }

    const appUid = appUserQuery.docs[0].id;
    await userRef.update({
      user_state: `waiting_for_conv_amount_${type}`,
      pending_app_uid: appUid,
      pending_app_id: appId
    });

    const name = type === 'gems' ? "مجوهرات 💎" : "كوينز 💰";
    const rate = type === 'gems' ? "10 جواهر لكل 100 نقطة" : "20 كوينز لكل 100 نقطة";
    await sendMessage(chat_id, `✅ **تم تأكيد حساب التطبيق: ${appId}**\n\nأدخل الآن **عدد النقاط** التي تريد تحويلها:\n(تذكّر: ${rate})`);
  }
  else if (state.startsWith("waiting_for_conv_amount_")) {
    const type = state.replace("waiting_for_conv_amount_", "") as 'gems' | 'coins';
    const points = parseInt(text.trim());

    if (isNaN(points) || points < 100) {
      await sendMessage(chat_id, "❌ الحد الأدنى للتحويل هو **100 نقطة**.");
      return;
    }

    if ((userData?.points || 0) < points) {
      await sendMessage(chat_id, `❌ **نقاطك غير كافية!** رصيدك: \`${userData?.points || 0}\` نقطة.`);
      return;
    }

    const appUid = userData?.pending_app_uid;
    const appId = userData?.pending_app_id;
    const rate = type === 'gems' ? 0.1 : 0.2;
    const reward = Math.floor(points * rate);
    const rewardName = type === 'gems' ? "جوهرة 💎" : "كوينز 💰";

    await executeAppConversion(chat_id, appUid, points, reward, type, appId);
    await userRef.update({
      user_state: admin.firestore.FieldValue.delete(),
      pending_app_uid: admin.firestore.FieldValue.delete(),
      pending_app_id: admin.firestore.FieldValue.delete()
    });
  }
  // 3. Agency Creation Flow
  else if (state === "waiting_for_agency_name") {
    await userRef.update({
      user_state: "waiting_for_agency_logo",
      pending_agency_name: text.trim()
    });
    await sendMessage(chat_id, "✅ **اسم الوكالة محفوظ.**\n\nيرجى الآن إرسال **رابط شعار (Logo)** الوكالة:");
  }
  else if (state === "waiting_for_agency_logo") {
    const agencyName = userData?.pending_agency_name;
    const appUid = userData?.app_uid;
    const cost = 1000000;

    await db.runTransaction(async (transaction) => {
      // 1. Deduct Points
      transaction.update(userRef, {
        points: admin.firestore.FieldValue.increment(-cost)
      });

      // 2. Create Request
      const requestRef = db.collection("agency_requests").doc();
      transaction.set(requestRef, {
        userId: chat_id,
        appUid: appUid,
        name: agencyName,
        logoUrl: text.trim(),
        status: "pending",
        costPoints: cost,
        createdAt: admin.firestore.FieldValue.serverTimestamp()
      });

      // 3. Log History
      const logRef = userRef.collection("history").doc();
      transaction.set(logRef, {
        type: "agency_establishment_request",
        name: agencyName,
        amount: cost,
        timestamp: admin.firestore.FieldValue.serverTimestamp()
      });
    });

    await userRef.update({
      user_state: admin.firestore.FieldValue.delete(),
      pending_agency_name: admin.firestore.FieldValue.delete()
    });

    await sendMessage(chat_id, "✅ **تم استلام طلب تأسيس الوكالة وخصم النقاط!** 👑\n\nسيتم مراجعة طلبك من قبل الإدارة والموافقة عليه خلال 24 ساعة. ستصلك رسالة فور التفعيل وظهور وكالتك في القائمة الرسمية.");
  }
  // 4. Family Creation Flow
  else if (state === "waiting_for_family_name") {
    const appUid = userData?.app_uid;
    const familyName = text.trim();
    const cost = 100000;

    // Create directly in App's families collection (Synced)
    const familyRef = db.collection("families").doc();
    await db.runTransaction(async (transaction) => {
      // 1. Deduct Points from Telegram
      transaction.update(userRef, {
        points: admin.firestore.FieldValue.increment(-cost)
      });

      // 2. Create Family
      transaction.set(familyRef, {
        name: familyName,
        creatorId: appUid,
        memberCount: 1,
        maxMembers: 50,
        level: 1,
        isVerified: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        familyGems: 0,
        familyCoins: 0,
      });

      // 3. Update User App Profile
      transaction.update(db.collection("users").doc(appUid), {
        familyId: familyRef.id,
        familyRole: "leader"
      });

      // 4. Log History
      const logRef = userRef.collection("history").doc();
      transaction.set(logRef, {
        type: "family_establishment",
        name: familyName,
        amount: cost,
        timestamp: admin.firestore.FieldValue.serverTimestamp()
      });
    });

    await userRef.update({ user_state: admin.firestore.FieldValue.delete() });
    await sendMessage(chat_id, `✅ **تم خصم \`${cost}\` نقطة وتأسيس عائلة (${familyName}) بنجاح.** 👨‍👩‍👧‍👦\n\nيمكنك الآن رؤية عائلتك داخل التطبيق ودعوة الأعضاء إليها.`);
  }
  else if (state.startsWith("waiting_ss_")) {
    const type = state.replace("waiting_ss_", "");
    if (photo && photo.length > 0) {
      const fileId = photo[photo.length - 1].file_id;
      // Record for admin review
      await db.collection("task_reviews").add({
        userId: chat_id,
        type: type,
        fileId: fileId,
        status: "pending",
        timestamp: admin.firestore.FieldValue.serverTimestamp()
      });
      await userRef.update({ user_state: admin.firestore.FieldValue.delete() });
      await sendMessage(chat_id, "✅ <b>تم استلام الإثبات!</b>\nجاري مراجعة الصورة من قبل الإدارة وسوف تحصل على النقاط فور الموافقة.");

      // Notify Admin
      const adminId = 8395753074; // First admin
      await sendMessage(adminId, `🔔 <b>طلب مراجعة مهمة (${type})</b>\nالمستخدم: <code>${chat_id}</code>\nيرجى مراجعة الصورة في قاعدة البيانات.`);
    } else {
      await sendMessage(chat_id, "❌ يرجى إرسال صورة (Screenshot) فقط.");
    }
  }
}

/**
 * ✅ Execute Conversion to App
 */
async function executeAppConversion(tgUserId: number, appUid: string, points: number, reward: number, type: 'gems' | 'coins', appId: string) {
  const tgRef = db.collection("telegram_users").doc(tgUserId.toString());
  const appRef = db.collection("users").doc(appUid);

  try {
    await db.runTransaction(async (transaction) => {
      // Deduct from TG
      transaction.update(tgRef, {
        points: admin.firestore.FieldValue.increment(-points)
      });

      // Add to App
      const updateData: any = {};
      if (type === 'gems') {
        updateData.gems = admin.firestore.FieldValue.increment(reward);
        updateData.rewardGems = admin.firestore.FieldValue.increment(reward);
      } else {
        updateData.coins = admin.firestore.FieldValue.increment(reward);
      }
      transaction.update(appRef, updateData);

      // Logs
      const logRef = tgRef.collection("history").doc();
      transaction.set(logRef, {
        type: `conv_to_${type}`,
        appId,
        pointsDeducted: points,
        rewardReceived: reward,
        timestamp: admin.firestore.FieldValue.serverTimestamp()
      });
    });

    const rewardName = type === 'gems' ? "جوهرة 💎" : "كوينز 💰";
    await sendMessage(tgUserId, `✅ **تم التحويل بنجاح!** 🎊\n\nتم خصم \`${points}\` نقطة وتحويلها إلى \`${reward}\` ${rewardName} في حساب التطبيق (ID: ${appId}).`);
  } catch (error) {
    console.error("App Conv Error:", error);
    await sendMessage(tgUserId, "❌ حدث خطأ أثناء عملية التحويل.");
  }
}

/**
 * ✅ Execute Transfer between users
 */
async function executeUserTransfer(senderId: number, targetId: string, amount: number) {
  const senderRef = db.collection("telegram_users").doc(senderId.toString());
  const targetRef = db.collection("telegram_users").doc(targetId);

  try {
    await db.runTransaction(async (transaction) => {
      // 1. Deduct from sender
      transaction.update(senderRef, {
        points: admin.firestore.FieldValue.increment(-amount)
      });

      // 2. Add to target
      transaction.update(targetRef, {
        points: admin.firestore.FieldValue.increment(amount)
      });

      // 3. Log for sender
      const sLog = senderRef.collection("history").doc();
      transaction.set(sLog, {
        type: "transfer_sent",
        to: targetId,
        amount: amount,
        timestamp: admin.firestore.FieldValue.serverTimestamp()
      });

      // 4. Log for receiver
      const rLog = targetRef.collection("history").doc();
      transaction.set(rLog, {
        type: "transfer_received",
        from: senderId.toString(),
        amount: amount,
        timestamp: admin.firestore.FieldValue.serverTimestamp()
      });
    });

    // Notify both
    await sendMessage(senderId, `✅ **تم تحويل \`${amount}\` نقطة بنجاح إلى صديقك!**`);
    await sendMessage(parseInt(targetId), `🎁 **وصلتك هدية!**\nلقد قام المستخدم (ID: ${senderId}) بتحويل \`${amount}\` نقطة إلى رصيدك. ✨`);

  } catch (error) {
    console.error("Transfer Error:", error);
    await sendMessage(senderId, "❌ حدث خطأ أثناء التحويل. يرجى المحاولة لاحقاً.");
  }
}

/**
 * 🎤 Handle Voice Rooms
 */
async function handleVoiceRooms(chat_id: number, message_id: number) {
  const text = `🎤 **الغرف الصوتية**

🎵 غرفة الموسيقى
📚 غرفة الأدب
💼 غرفة الأعمال
🎮 غرفة الألعاب`;

  const keyboard = {
    inline_keyboard: [
      [
        { text: "🎵 الموسيقى", callback_data: "join_room_music" },
        { text: "📚 الأدب", callback_data: "join_room_literature" },
      ],
      [
        { text: "💼 الأعمال", callback_data: "join_room_business" },
        { text: "🎮 الألعاب", callback_data: "join_room_games" },
      ],
      [{ text: "⬅️ الرجوع", callback_data: "back_to_menu" }],
    ],
  };

  await editMessage(chat_id, message_id, text, keyboard);
}

/**
 * 👥 Handle Referrals
 */
/**
 * 👥 Handle Referrals (Invite Friends)
 */
async function handleReferrals(chat_id: number, message_id: number) {
  const tgInviteText = encodeURIComponent("انضم إلي في رويال دور واحصل على مكافآت ملكية! 👑✨");
  const tgInviteLink = `https://t.me/share/url?url=https://t.me/royaldoor_bot?start=tg_${chat_id}&text=${tgInviteText}`;

  const smInviteLink = `https://t.me/royaldoor_bot?start=sm_${chat_id}`;

  const text = `👥 **دعوة الأصدقاء والمكافآت** 👥

اختر الطريقة المناسبة لك لدعوة أصدقائك واكسب النقاط الملكية:

1️⃣ **دعوة أصدقاء التلغرام:**
ارسل دعوة مباشرة لأصدقائك في التلغرام.
💰 المكافأة: **2 نقطة** لكل شخص ينضم.

2️⃣ **دعوة عبر السوشل ميديا:**
شارك رابطك الخاص في فيسبوك، تيك توك، أو واتساب.
💰 المكافأة: **5 نقاط** لكل شخص ينضم.

---
🔗 **رابط السوشل ميديا الخاص بك:**
\`${smInviteLink}\``;

  const keyboard = {
    inline_keyboard: [
      [{ text: "✈️ دعوة أصدقاء التلغرام", url: tgInviteLink }],
      [{ text: "📱 مشاركة عبر السوشل ميديا", callback_data: "share_sm_info" }],
      [{ text: "⬅️ الرجوع", callback_data: "back_to_menu" }],
    ],
  };

  await editMessage(chat_id, message_id, text, keyboard);
}

/**
 * 💼 Handle Investment
 */
/**
 * 💼 Handle Investment
 */
async function handleInvestment(chat_id: number, message_id: number) {
  const text = `📊 **باقات الاستثمار الملكي** 👑

"حول نجومك إلى أرباح حقيقية بضمانة Royal Door"

✨ **الباقات المتاحة:**
1. **الدر ☀️:** 100,000 دينار | الربح: +1,900 | الإجمالي: 40,400
2. **المرجان 🔴:** 200,000 دينار | الربح: +3,800 | الإجمالي: 80,800
3. **العقيق 🟤:** 300,000 دينار | الربح: +5,700 | الإجمالي: 120,700
4. **الكريستال 🔷:** 500,000 دينار | الربح: +9,600 | الإجمالي: 201,600
5. **الزبرجد 🟢:** 750,000 دينار | الربح: +14,400 | الإجمالي: 302,400
6. **اللؤلؤ 🤍:** 1,000,000 دينار | الربح: +19,200 | الإجمالي: 404,200
7. **الفيروز 💠:** 1,200,000 دينار | الربح: +23,000 | الإجمالي: 485,000
8. **الماس 💎:** 1,300,000 دينار | الربح: +25,000 | الإجمالي: 525,000
9. **الزمرد 🟩:** 1,400,000 دينار | الربح: +27,000 | الإجمالي: 565,000
10. **الياقوت 🔸:** 1,500,000 دينار | الربح: +29,000 | الإجمالي: 606,000

⚠️ لتفعيل أي باقة، يجب ربط حسابك في التطبيق بالبوت أولاً.`;

  const keyboard = {
    inline_keyboard: [
      [
        { text: "☀️ الدر", callback_data: "buy_durra" },
        { text: "🔴 المرجان", callback_data: "buy_morjan" },
      ],
      [
        { text: "🟤 العقيق", callback_data: "buy_aqeeq" },
        { text: "🔷 الكريستال", callback_data: "buy_crystal" },
      ],
      [
        { text: "🟢 الزبرجد", callback_data: "buy_zabarjad" },
        { text: "🤍 اللؤلؤ", callback_data: "buy_lulu" },
      ],
      [
        { text: "🛒 المزيد من الباقات", callback_data: "more_packages" },
      ],
      [{ text: "⬅️ الرجوع", callback_data: "back_to_menu" }],
    ],
  };

  await editMessage(chat_id, message_id, text, keyboard);
}

/**
 * 🛒 Handle More Packages
 */
async function handleMorePackages(chat_id: number, message_id: number) {
  const text = `📊 **باقات الاستثمار الملكي (تابع)** 👑`;
  const keyboard = {
    inline_keyboard: [
      [
        { text: "💠 الفيروز", callback_data: "buy_fayrouz" },
        { text: "💎 الماس", callback_data: "buy_almas" },
      ],
      [
        { text: "🟩 الزمرد", callback_data: "buy_zumurrud" },
        { text: "🔸 الياقوت", callback_data: "buy_yaqoot" },
      ],
      [{ text: "⬅️ الرجوع للباقات", callback_data: "investment" }],
    ],
  };
  await editMessage(chat_id, message_id, text, keyboard);
}

/**
 * 💳 Handle Purchase Logic
 */
async function handlePurchasePackage(chat_id: number, packageId: string) {
  const userDoc = await db.collection("telegram_users").doc(chat_id.toString()).get();
  const userData = userDoc.data();

  if (!userData?.app_uid) {
    await sendMessage(chat_id, "❌ **عذراً! حسابك غير مرتبط بالتطبيق.**\n\nيرجى فتح التطبيق والانتقال لصفحة البوت لربط حسابك أولاً لتتمكن من الشراء من رصيدك.");
    return;
  }

  const appUid = userData.app_uid;
  const packageRef = await db.collection("reward_packages").doc(packageId).get();

  if (!packageRef.exists) {
    await sendMessage(chat_id, "❌ الباقة غير موجودة حالياً.");
    return;
  }

  const pkg = packageRef.data()!;
  const cost = pkg.stars_cost || pkg.cost;

  try {
    await db.runTransaction(async (transaction) => {
      const appUserRef = db.collection("users").doc(appUid);
      const appUserDoc = await transaction.get(appUserRef);

      if (!appUserDoc.exists) throw new Error("User not found in app");

      const appUserData = appUserDoc.data()!;
      const balance = appUserData.harvest_stars_wallet || 0;

      if (balance < cost) {
        throw new Error("Insufficient balance");
      }

      // Deduct balance
      transaction.update(appUserRef, {
        harvest_stars_wallet: admin.firestore.FieldValue.increment(-cost),
        rewardStars: admin.firestore.FieldValue.increment(-cost),
      });

      // Add active reward
      const activeRewardRef = appUserRef.collection("active_rewards").doc();
      const now = admin.firestore.Timestamp.now();
      const duration = pkg.durationDays || 30;

      transaction.set(activeRewardRef, {
        userId: appUid,
        packageName: pkg.name,
        rewardAmount: cost,
        totalReward: pkg.total_reward,
        dailyReward: pkg.daily_reward,
        startTime: now,
        endTime: admin.firestore.Timestamp.fromMillis(now.toMillis() + (duration * 24 * 60 * 60 * 1000)),
        status: "active",
        paymentMethod: "stars",
        metadata: {
          source: "telegram_bot",
          activated_at: now,
        }
      });
    });

    await sendMessage(chat_id, `✅ **تم تفعيل باقة (${pkg.name}) بنجاح!** 🎊\n\nتم خصم ${cost} من رصيدك. سيبدأ الحصاد اليومي تلقائياً.`);
  } catch (error: any) {
    if (error.message === "Insufficient balance") {
      await sendMessage(chat_id, `❌ **رصيدك غير كافٍ!**\nتحتاج إلى ${cost} نجمة لتفعيل هذه الباقة.`);
    } else {
      console.error("Purchase Error:", error);
      await sendMessage(chat_id, "❌ حدث خطأ أثناء تفعيل الباقة. يرجى المحاولة لاحقاً.");
    }
  }
}

/**
 * ❓ Handle FAQ (Common Questions)
 */
async function handleFAQ(chat_id: number, message_id: number) {
  const text = `❓ **الأسئلة الشائعة - Royal Door** ❓

**س: كيف أشحن الجواهر؟**
ج: اختر الباقة من صفحة الشحن، أدخل الآيدي (ID) الصحيح الخاص بك في التطبيق، واضغط على زر واتساب للتواصل مع الوكيل الخاص بمحافظتك أو من ينوب عنه.

**س: ماهو الاستثمار وكم يستغرق؟**
ج: هي عملية شراء جواهر واستثمارها في التطبيق لمدة ٣٠ يوم. بعد انتهاء المدة تحصل على عائد أو راتب حسب نوع الباقة( مثل السلفه العراقيه ). كل باقة لها ربحها اليومي والشهري، وتستطيع الاستمرار بعد شهر بتفعيل باقة أخرى أو سحب أرباحك كاملة. رويال دور منصة آمنة وموثقة قانونياً عبر قبول تطبيقنا في منصة جوجل، كما يمكنك شراء وتفعيل الباقات من خانة "المكافآت الملكية" أو بيع باقتك في سوق بيع الباقات إذا احتجت لأموالك.

⚠️ **تنويه هام:** قمنا بتصميم هذه العملية بهذا الأسلوب لتجنب خصم عمولات جوجل (التي تصل لثلث المبلغ)، لضمان وصول المبلغ كاملاً إليك؛ فإذا اشتريت 100 جوهرة، تحصل على 100 جوهرة بنفس السعر. سعر الدولار المعتمد هو 1300 دينار.

**س: هل توجد رسوم على التحويلات المالية؟**
ج: يمكنك تحويل أموالك من حساب لآخر ومن شخص لآخر داخل منصة "المكافآت الملكية" بعمولة 5% فقط كأجور تحويل.

**س: هل الشحن آمن؟**
ج: نعم، الشحن يتم عبر الوكلاء الرسميين المعتمدين في الموقع والتطبيق حصراً ويضمنون وصول الأموال إلى حسابك مباشرة. أي وكيل لم يُذكر في قائمة الوكلاء بالموقع الرسمي فهو ليس تابعاً للتطبيق.`;

  const keyboard = {
    inline_keyboard: [
      [{ text: "🏢 قائمة الوكلاء", callback_data: "agents" }],
      [{ text: "⬅️ الرجوع للمساعدة", callback_data: "help_menu" }],
    ],
  };

  await editMessage(chat_id, message_id, text, keyboard);
}
async function handleHelp(chat_id: number, message_id: number) {
  const text = `⚙ **مركز المساعدة والدعم** ⚙

مرحباً بك في مركز المساعدة الخاص بـ RoyalDoor.
كيف يمكننا مساعدتك اليوم؟`;

  const keyboard = {
    inline_keyboard: [
      [{ text: "💬 الدعم الفني وتواصل معنا", callback_data: "technical_support" }],
      [
        { text: "❓ الأسئلة الشائعة", callback_data: "faq" },
        { text: "📖 كيفية الاستخدام", callback_data: "tutorial" }
      ],
      [{ text: "ℹ️ عن RoyalDoor", callback_data: "about" }],
      [{ text: "⬅️ الرجوع للقائمة الرئيسية", callback_data: "back_to_menu" }],
    ],
  };

  await editMessage(chat_id, message_id, text, keyboard);
}

/**
 * 💬 Handle Technical Support (Social Links)
 */
async function handleTechnicalSupport(chat_id: number, message_id: number) {
  const text = `💬 **الدعم الفني - قنوات التواصل** 💬

يسعدنا تواصلكم معنا عبر منصاتنا الرسمية. فريق الدعم متاح للرد على استفساراتكم على مدار الساعة.`;

  const keyboard = {
    inline_keyboard: [
      [
        { text: "🎵 تيك توك", url: "https://www.tiktok.com/@royaldoor86?is_from_webapp=1&sender_device=pc" },
        { text: "📺 يوتيوب", url: "https://www.youtube.com/@royaldoor" },
        { text: "🔵 فيسبوك", url: "https://www.facebook.com/share/18WCKqfb8u/" }
      ],
      [
        { text: "📸 انستقرام", url: "https://www.instagram.com/royaldoor86?igsh=aHp5cG90aTAxcnU5" },
        { text: "✈️ تيليجرام", url: "https://t.me/royal9door" },
        { text: "🟢 واتساب", url: "https://wa.me/9647770992966" }
      ],
      [{ text: "⬅️ الرجوع للمساعدة", callback_data: "help_menu" }],
    ],
  };

  await editMessage(chat_id, message_id, text, keyboard);
}

/**
 * ℹ️ Handle About RoyalDoor (Detailed Pages)
 */
async function handleAbout(chat_id: number, message_id: number) {
  const text = `👑 **حول رويال دور (Royal Door)** 👑

بوابتك الملكية إلى عالم من الترفيه والتواصل الاجتماعي الراقي.

✨ **ما هو رويال دور؟**
تطبيق غرف صوتية وألعاب جماعية مصمم ليجمع الأصدقاء في جو ترفيهي ممتع، مع نظام رومات، بروفايل متطور، وهدايا وتأثيرات جميلة داخل الغرفة.

🌟 **المميزات الملكية:**
• 🎙 **الغرف الصوتية:** للتواصل الفوري والفعاليات.
• 🎮 **الألعاب التفاعلية:** لزيادة المتعة والمنافسة.
• 🎁 **الهدايا الرقمية:** إطارات وتأثيرات فاخرة تعزز هويتك.

🎯 **رؤيتنا:**
أن نصنع منصة اجتماعية راقية، حيث يلتقي الترف الملكي مع التقنية الحديثة.

📊 **الإصدار:** 1.0.0 (نسخة الديوان الملكي)
🔗 **الموقع الرسمي:** www.royaldoor.live`;

  const keyboard = {
    inline_keyboard: [
      [{ text: "🛡️ سياسة الخصوصية", callback_data: "view_privacy" }],
      [{ text: "📜 شروط الاستخدام", callback_data: "view_terms" }],
      [{ text: "⭐ قيمنا وادعمنا على Play Store", url: "https://play.google.com/store/apps/details?id=com.royaldoor.live" }],
      [{ text: "⬅️ الرجوع للقائمة الرئيسية", callback_data: "back_to_menu" }],
    ],
  };

  await editMessage(chat_id, message_id, text, keyboard);
}

/**
 * 🛡️ Handle View Privacy Policy
 */
async function handleViewPrivacy(chat_id: number, message_id: number) {
  const text = `🛡️ **سياسة الخصوصية - Royal Door** 🛡️

نحن في تطبيق Royal Door نلتزم بحماية خصوصيتك واتباع سياسات Google Play المتعلقة بالبيانات.

• **البيانات التي نجمعها:**
- معلومات الحساب: الاسم، البريد الإلكتروني، صورة الملف الشخصي.
- محتوى المستخدم: الرسائل، الصور، الفيديو، والصوت.
- بيانات الجهاز والاستخدام: نوع الجهاز والنشاط داخل التطبيق.

• **كيف نستخدم البيانات:**
- لتشغيل وظائف التطبيق الأساسية (الغرف والدردشة).
- لإدارة الحساب والمصادقة.
- لتحسين جودة التطبيق وحمايته من الاحتيال.

• **الأذونات المطلوبة:**
- الكاميرا والميكروفون (للمكالمات).
- الصور والفيديو (للملف الشخصي).
- الإشعارات والإنترنت.

• **حقوقك:**
يمكنك طلب الاطلاع على بياناتك أو تعديلها أو حذفها بالكامل من التطبيق.

📅 *آخر تحديث: أبريل 2026*`;

  const keyboard = {
    inline_keyboard: [[{ text: "⬅️ الرجوع", callback_data: "about" }]],
  };

  await editMessage(chat_id, message_id, text, keyboard);
}

/**
 * 📜 Handle View Terms of Use
 */
async function handleViewTerms(chat_id: number, message_id: number) {
  const text = `📜 **شروط الاستخدام - Royal Door** 📜

باستخدام تطبيق Royal Door، فإنك توافق على الالتزام بالشروط التالية:

1️⃣ **أهلية الاستخدام:** يجب أن يكون عمرك 13 عاماً أو أكثر.
2️⃣ **سلوك المستخدم:** يمنع استخدام التطبيق لأي غرض غير قانوني أو نشر محتوى مسيء. يجب احترام الجميع.
3️⃣ **المحتوى:** أنت المسؤول عن أي محتوى تنشره. لا يجوز انتهاك حقوق الملكية الفكرية.
4️⃣ **الأمان:** أنت مسؤول عن الحفاظ على سرية بيانات حسابك.
5️⃣ **المشتريات:** العملات الرقمية داخل التطبيق غير قابلة للتحويل خارج النظام.
6️⃣ **التعليق:** نحتفظ بالحق في إيقاف الحسابات التي تنتهك القوانين دون إشعار مسبق.

استمرارك في استخدام التطبيق يعني قبولك للإصدار الأخير من هذه الشروط.

📅 *آخر تحديث: أبريل 2026*`;

  const keyboard = {
    inline_keyboard: [[{ text: "⬅️ الرجوع", callback_data: "about" }]],
  };

  await editMessage(chat_id, message_id, text, keyboard);
}

/**
 * 👤 Handle Account Menu
 */
async function handleAccountMenu(chat_id: number, message_id: number) {
  const text = `👤 **إدارة الحساب الملكي** 👤

أهلاً بك في قسم إدارة حسابك. يمكنك هنا متابعة رصيدك وتفاصيل نشاطك والمطالبة بمكافآتك اليومية.`;

  const keyboard = {
    inline_keyboard: [
      [
        { text: "🪪 معلومات الحساب", callback_data: "profile" },
        { text: "🎁 المكافآت اليومية", callback_data: "daily_rewards_menu" }
      ],
      [
        { text: "📜 سجل العمليات", callback_data: "history" },
        { text: "⭐ مستوى العضوية", callback_data: "vip" }
      ],
      [{ text: "⬅️ الرجوع للقائمة الرئيسية", callback_data: "back_to_menu" }],
    ],
  };

  await editMessage(chat_id, message_id, text, keyboard);
}

/**
 * 📰 Handle Media Center Menu
 */
async function handleMediaCenterMenu(chat_id: number, message_id: number) {
  const text = `📰 **المركز الإعلامي الملكي** 📰

تابع أحدث الأخبار والعروض والمسابقات الحصرية لرويال دور.`;

  const keyboard = {
    inline_keyboard: [
      [{ text: "📢 الأخبار", callback_data: "news" }],
      [
        { text: "🎉 العروض الحصرية", callback_data: "offers" },
        { text: "🎁 المسابقات", callback_data: "contests" }
      ],
      [{ text: "⬅️ الرجوع للقائمة الرئيسية", callback_data: "back_to_menu" }],
    ],
  };

  await editMessage(chat_id, message_id, text, keyboard);
}

/**
 * 🎁 Handle Daily Rewards Menu
 */
async function handleDailyRewardsMenu(chat_id: number, message_id: number) {
  const userRef = db.collection("telegram_users").doc(chat_id.toString());
  const userDoc = await userRef.get();
  const userData = userDoc.data();

  const lastHarvest = userData?.last_harvest?.toDate();
  const now = new Date();
  let canHarvest = true;
  let remainingTime = "";

  if (lastHarvest) {
    const diff = now.getTime() - lastHarvest.getTime();
    const hours24 = 24 * 60 * 60 * 1000;
    if (diff < hours24) {
      canHarvest = false;
      const remainingMs = hours24 - diff;
      const hours = Math.floor(remainingMs / (1000 * 60 * 60));
      const minutes = Math.floor((remainingMs % (1000 * 60 * 60)) / (1000 * 60));
      remainingTime = `${hours} ساعة و ${minutes} دقيقة`;
    }
  }

  const text = `🎁 **المكافآت اليومية الملكية** 🎁

استلم هديتك اليومية من النقاط لتعزيز رصيدك!

💰 الجائزة الحالية: **2 نقطة**
⏰ التكرار: **كل 24 ساعة**

${canHarvest ? "✅ المكافأة جاهزة للحصد الآن!" : `⏳ يرجى الانتظار \`${remainingTime}\` لتتمكن من الحصد مرة أخرى.`}`;

  const keyboard = {
    inline_keyboard: [
      canHarvest
        ? [{ text: "✨ حصد النقاط ✨", callback_data: "harvest_daily_points" }]
        : [{ text: "⏳ العودة لاحقاً", callback_data: "none" }],
      [{ text: "⬅️ الرجوع للحساب", callback_data: "account_menu" }],
    ],
  };

  await editMessage(chat_id, message_id, text, keyboard);
}

/**
 * ✨ Process Harvest Points
 */
async function handleHarvestPoints(chat_id: number) {
  const userRef = db.collection("telegram_users").doc(chat_id.toString());

  try {
    await db.runTransaction(async (transaction) => {
      const userDoc = await transaction.get(userRef);
      const userData = userDoc.data();

      const lastHarvest = userData?.last_harvest?.toDate();
      const now = new Date();
      const hours24 = 24 * 60 * 60 * 1000;

      if (lastHarvest && (now.getTime() - lastHarvest.getTime() < hours24)) {
        throw new Error("Already harvested within 24h");
      }

      transaction.update(userRef, {
        points: admin.firestore.FieldValue.increment(2),
        last_harvest: admin.firestore.FieldValue.serverTimestamp()
      });

      // Log it
      const logRef = userRef.collection("history").doc();
      transaction.set(logRef, {
        type: "daily_harvest",
        pointsGained: 2,
        timestamp: admin.firestore.FieldValue.serverTimestamp()
      });
    });

    await sendMessage(chat_id, "🎉 **مبروك!** لقد حصدت `2` نقطة ملكية بنجاح. عد بعد 24 ساعة للحصول على المزيد!");
  } catch (error: any) {
    if (error.message === "Already harvested within 24h") {
      await sendMessage(chat_id, "⚠️ عذراً، لقد قمت بالحصد بالفعل خلال الـ 24 ساعة الماضية.");
    } else {
      console.error("Harvest Error:", error);
    }
  }
}

/**
 * 📢 Handle Funding (Channel/Group Promotion)
 */
async function handleFunding(chat_id: number, message_id: number) {
  const text = `📢 **تمويل القنوات والمجموعات الملكية** 🚀

استخدم نقاطك لزيادة أعضاء قناتك أو مجموعتك بسرعة واحترافية.

💎 **أسعار التمويل الحالية:**
• **100 عضو حقيقي** = **2,500 نقطة**
• **200 عضو حقيقي** = **4,500 نقطة** (توفير 500)
• **500 عضو حقيقي** = **10,000 نقطة** (توفير 2500)

⚠️ **طريقة العمل:**
1. اختر الباقة المطلوبة.
2. أرسل رابط القناة/المجموعة.
3. سيتم خصم النقاط وبدء التمويل فوراً عبر نظامنا.

اختر الباقة المناسبة للبدء:`;

  const keyboard = {
    inline_keyboard: [
      [{ text: "👥 100 عضو (2500ن)", callback_data: "fund_req_100" }],
      [{ text: "👥 200 عضو (4500ن)", callback_data: "fund_req_200" }],
      [{ text: "👥 500 عضو (10000ن)", callback_data: "fund_req_500" }],
      [{ text: "⬅️ الرجوع", callback_data: "back_to_menu" }],
    ],
  };

  await editMessage(chat_id, message_id, text, keyboard);
}

/**
 * 📝 Handle Funding Request Logic
 */
async function handleFundingRequest(chat_id: number, amount: number, points: number) {
  const userRef = db.collection("telegram_users").doc(chat_id.toString());
  const userDoc = await userRef.get();
  const currentPoints = userDoc.data()?.points || 0;

  if (currentPoints < points) {
    await sendMessage(chat_id, `❌ **نقاطك غير كافية!**\nتحتاج إلى \`${points}\` نقطة لتفعيل باقة الـ \`${amount}\` عضو.`);
    return;
  }

  // Set state to wait for Link
  await userRef.update({
    waiting_for_link: true,
    pending_fund_amount: amount,
    pending_fund_cost: points
  });

  await sendMessage(chat_id, `🔗 **رائع! يرجى إرسال رابط القناة أو المجموعة الآن:**\n(مثال: https://t.me/your_channel)`);
}

/**
 * ✅ Process Final Funding with Link
 */
async function processFundingLink(chat_id: number, link: string) {
  const userRef = db.collection("telegram_users").doc(chat_id.toString());
  const userDoc = await userRef.get();
  const data = userDoc.data();

  if (!data?.waiting_for_link) return;

  const amount = data.pending_fund_amount;
  const cost = data.pending_fund_cost;

  try {
    await db.runTransaction(async (transaction) => {
      // Deduct points
      transaction.update(userRef, {
        points: admin.firestore.FieldValue.increment(-cost),
        waiting_for_link: false,
        pending_fund_amount: admin.firestore.FieldValue.delete(),
        pending_fund_cost: admin.firestore.FieldValue.delete()
      });

      // Create Task for system/admins
      const taskRef = db.collection("funding_requests").doc();
      transaction.set(taskRef, {
        userId: chat_id,
        channelLink: link,
        membersCount: amount,
        costPoints: cost,
        status: "processing",
        createdAt: admin.firestore.FieldValue.serverTimestamp()
      });

      // Log history
      const logRef = userRef.collection("history").doc();
      transaction.set(logRef, {
        type: "channel_funding",
        amount,
        cost,
        link,
        timestamp: admin.firestore.FieldValue.serverTimestamp()
      });
    });

    await sendMessage(chat_id, `✅ **تم استلام طلب التمويل بنجاح!** 🎊\n\nباقة: \`${amount}\` عضو\nالرابط: \`${link}\` \n\nسيتم اكتمال الطلب خلال 24 ساعة كحد أقصى. شكراً لثقتك بـ رويال دور!`);
  } catch (error) {
    console.error("Funding Finalize Error:", error);
    await sendMessage(chat_id, "❌ حدث خطأ أثناء معالجة الطلب. يرجى التواصل مع الدعم.");
  }
}

/**
 * 👤 Handle Profile (Account Info)
 */
async function handleProfile(chat_id: number, message_id: number) {
  try {
    const userDoc = await db.collection("telegram_users").doc(chat_id.toString()).get();
    const userData = userDoc.data();

    const appId = userData?.app_uid ? `<code>${escapeHTML(userData.app_uid)}</code>` : "<i>غير مرتبط</i>";

    const text = `🪪 <b>معلومات الحساب الملكي</b>

📱 <b>الاسم:</b> ${escapeHTML(userData?.first_name || "مستخدم")}
🆔 <b>Telegram ID:</b> <code>${chat_id}</code>
🆔 <b>App ID:</b> ${appId}
💎 <b>النقاط:</b> <code>${userData?.points || 0}</code>
⭐ <b>المستوى:</b> ${userData?.is_vip ? "VIP الملكي" : "عضو عادي"}
📅 <b>تاريخ الانضمام:</b> ${userData?.joined_at?.toDate().toLocaleDateString('ar-EG') || "غير معروف"}`;

    const keyboard = {
      inline_keyboard: [
        [{ text: "💰 رصيدي", callback_data: "balance" }],
        [{ text: "⬅️ الرجوع للحساب", callback_data: "account_menu" }],
      ],
    };

    await editMessage(chat_id, message_id, text, keyboard);
  } catch (error) {
    console.error("Profile Error:", error);
  }
}
async function handleBalance(chat_id: number, message_id: number) {
  const userDoc = await db.collection("telegram_users").doc(chat_id.toString()).get();
  const userData = userDoc.data();

  const balance = userData?.points || 0;
  const vipLevel = userData?.is_vip ? "VIP الملكي" : "عضو عادي";

  const text = `💰 **رصيدك الحالي**

👤 المستخدم: \`${userData?.first_name}\`
💎 النقاط: \`${balance}\` نقطة
⭐ المستوى: \`${vipLevel}\`

يمكنك استخدام هذه النقاط في تمويل قناتك أو تحويلها لهدايا داخل التطبيق.`;

  const keyboard = {
    inline_keyboard: [
      [{ text: "🎯 تجميع المزيد من النقاط", callback_data: "collect_points" }],
      [{ text: "🔄 تحويل النقاط", callback_data: "treasury" }],
      [{ text: "⬅️ الرجوع", callback_data: "back_to_menu" }],
    ],
  };

  await editMessage(chat_id, message_id, text, keyboard);
}

/**
 * 📅 Handle Daily Tasks (Dynamic Rewards)
 */
async function handleDailyTasks(chat_id: number, message_id: number) {
  const userRef = db.collection("telegram_users").doc(chat_id.toString());
  const userData = (await userRef.get()).data();

  const today = new Date().toISOString().split('T')[0];
  const completed = userData?.daily_tasks_done || [];
  const isDone = (task: string) => completed.includes(`${task}_${today}`);

  const text = `<b>📅 المهام اليومية المتجددة</b>\n\nأكمل المهام كل 24 ساعة لربح نقاط إضافية:\n\n` +
               `1️⃣ <b>مشاركة الرابط:</b> شارك البوت مع 5 أشخاص اليوم.\n` +
               `2️⃣ <b>يوتيوب رويال:</b> متابعة + تعليق على آخر فيديو (+3 نقاط).\n` +
               `3️⃣ <b>التسجيل اليومي:</b> مكافأة الحضور اليومي (+2 نقطة).`;

  const keyboard = {
    inline_keyboard: [
      [
        { text: isDone("share") ? "✅ تم" : "📤 مشاركة (5 أشخاص)", callback_data: "referrals" },
        { text: isDone("youtube") ? "✅ تم" : "📺 يوتيوب رويال (+3)", callback_data: "verify_ss_youtube" }
      ],
      [
        { text: isDone("daily") ? "✅ تم الاستلام" : "🎁 مكافأة الحضور (+2)", callback_data: "daily_claim" }
      ],
      [{ text: "⬅️ الرجوع", callback_data: "back_to_menu" }]
    ]
  };

  await editMessage(chat_id, message_id, text, keyboard);
}

/**
 * 📸 Start Screenshot Submission Task
 */
async function startScreenshotTask(chat_id: number, type: string) {
  await db.collection("telegram_users").doc(chat_id.toString()).update({
    user_state: `waiting_ss_${type}`
  });

  const names: any = {
    tiktok: "تيك توك",
    facebook: "فيسبوك",
    youtube: "يوتيوب (متابعة + تعليق)"
  };
  const name = names[type] || type;

  let msg = `📸 <b>إثبات مهمة ${name}</b>\n\n`;
  if (type === "youtube") {
    msg += `1️⃣ اذهب للقناة: https://youtube.com/@royaldoor?si=af-BiV7nMcLSmr-W\n` +
           `2️⃣ اشترك في القناة واترك تعليقاً على آخر فيديو.\n` +
           `3️⃣ ارسل <b>لقطة شاشة (Screenshot)</b> للتعليق والاشتراك.\n\n`;
  } else {
    msg += `يرجى إرسال <b>لقطة شاشة (Screenshot)</b> تظهر أنك قمت بمتابعة حسابنا.\n\n`;
  }

  msg += `سيتم مراجعة الصورة من قبل الإدارة ومنحك النقاط فور الموافقة.`;

  await sendMessage(chat_id, msg);
}

/**
 * 🎤 Verify REAL Gift Task (Check App DB)
 */
async function verifyRealGiftTask(chat_id: number) {
  const userData = (await db.collection("telegram_users").doc(chat_id.toString()).get()).data();
  if (!userData?.app_uid) {
    await sendMessage(chat_id, "❌ <b>يجب ربط حسابك بالتطبيق أولاً!</b>\nلا يمكننا التحقق من سجل هداياك دون ربط الحساب.");
    return;
  }

  // Real Check in "sent_gifts" collection
  const giftCheck = await db.collection("sent_gifts")
    .where("senderId", "==", userData.app_uid)
    .limit(1)
    .get();

  if (!giftCheck.empty) {
    await db.collection("telegram_users").doc(chat_id.toString()).update({
      points: admin.firestore.FieldValue.increment(10),
      completed_tasks: admin.firestore.FieldValue.arrayUnion("voice_gift_task")
    });
    await sendMessage(chat_id, "✅ <b>تم التحقق!</b> وجدنا سجل إرسال هداياك في التطبيق. تم منحك 10 نقاط.");
  } else {
    await sendMessage(chat_id, "❌ <b>لم نجد أي هدايا مرسلة!</b> يرجى إرسال هدية في أي غرفة صوتية ثم المحاولة مجدداً.");
  }
}

/**
 * 🏆 Verify REAL Event Task (Check App DB)
 */
async function verifyRealEventTask(chat_id: number) {
  const userData = (await db.collection("telegram_users").doc(chat_id.toString()).get()).data();
  if (!userData?.app_uid) {
    await sendMessage(chat_id, "❌ يجب ربط حسابك بالتطبيق أولاً!");
    return;
  }

  const eventCheck = await db.collection("users").doc(userData.app_uid).collection("active_rewards").limit(1).get();

  if (!eventCheck.empty) {
    await db.collection("telegram_users").doc(chat_id.toString()).update({
      points: admin.firestore.FieldValue.increment(10),
      completed_tasks: admin.firestore.FieldValue.arrayUnion("event_task")
    });
    await sendMessage(chat_id, "✅ <b>تم التحقق!</b> أنت مشارك نشط في فعاليات التطبيق. تم منحك 10 نقاط.");
  } else {
    await sendMessage(chat_id, "❌ لم نجد أي مشاركة في الفعاليات حالياً.");
  }
}

/**
 * 🎯 Handle Collect Points (Tasks)
 */
async function handleCollectPoints(chat_id: number, message_id: number) {
  try {
    const userDoc = await db.collection("telegram_users").doc(chat_id.toString()).get();
    const userData = userDoc.data();
    const completedTasks = userData?.completed_tasks || [];

    const text = `🎯 <b>تجميع النقاط (تحقق حقيقي)</b>\n\nأكمل المهام للحصول على مكافآت فورية:`;

    const keyboard = {
      inline_keyboard: [
        [
          { text: completedTasks.includes("join_channel") ? "✅ تم" : "📢 القناة (+5)", url: "https://t.me/royaldur" },
          { text: "🔍 تحقق", callback_data: "verify_channel" }
        ],
        [
          { text: "📸 تيك توك (+10)", callback_data: "verify_ss_tiktok" },
          { text: "📸 فيسبوك (+10)", callback_data: "verify_ss_facebook" }
        ],
        [
          { text: "🎤 إرسال هدية (+10)", callback_data: "verify_gift_task" },
          { text: "🏆 فعاليات (+10)", callback_data: "verify_event_task" }
        ],
        [{ text: "⬅️ الرجوع", callback_data: "back_to_menu" }],
      ],
    };

    await editMessage(chat_id, message_id, text, keyboard);
  } catch (error) {
    console.error("Collect Points Error:", error);
  }
}

/**
 * 🔍 Verify Task Logic
 */
async function verifyTask(chat_id: number, taskId: string, points: number, telegramChatId?: string) {
  const userRef = db.collection("telegram_users").doc(chat_id.toString());
  const userDoc = await userRef.get();
  const userData = userDoc.data();

  if (userData?.completed_tasks?.includes(taskId)) {
    await sendMessage(chat_id, "⚠️ لقد حصلت على نقاط هذه المهمة مسبقاً!");
    return;
  }

  let isVerified = false;

  if (telegramChatId) {
    try {
      const response = await axios.get(`${TELEGRAM_API}/getChatMember?chat_id=${telegramChatId}&user_id=${chat_id}`);
      const status = response.data.result.status;
      if (["member", "administrator", "creator"].includes(status)) {
        isVerified = true;
      }
    } catch (e) {
      console.error("Verification Error:", e);
    }
  } else {
    // For social media (TikTok/FB), we simulate verification for now
    // In a real scenario, you might need an API or manual check
    isVerified = true;
  }

  if (isVerified) {
    await userRef.update({
      points: admin.firestore.FieldValue.increment(points),
      completed_tasks: admin.firestore.FieldValue.arrayUnion(taskId)
    });
    await sendMessage(chat_id, `✅ أحسنت! تم التحقق من المهمة وإضافة \`${points}\` نقطة لرصيدك.`);
  } else {
    await sendMessage(chat_id, "❌ لم نتمكن من التحقق من إتمام المهمة. يرجى التأكد من الانضمام أولاً.");
  }
}

/**
 * ❤️ Process Reaction Reward
 */
async function handleReactionReward(userId: number, messageId: number) {
  try {
    const userRef = db.collection("telegram_users").doc(userId.toString());
    const interactionRef = userRef.collection("interactions").doc(messageId.toString());
    const interactionDoc = await interactionRef.get();

    // Prevent duplicate rewards for the same message
    if (!interactionDoc.exists) {
      await db.runTransaction(async (transaction) => {
        transaction.update(userRef, {
          points: admin.firestore.FieldValue.increment(1),
          collective_points: admin.firestore.FieldValue.increment(1)
        });

        transaction.set(interactionRef, {
          type: "reaction",
          messageId: messageId,
          rewardedAt: admin.firestore.FieldValue.serverTimestamp()
        });
      });

      await sendMessage(userId, "❤️ شكراً لتفاعلك! لقد حصلت على `1` نقطة ملكية.");
    }
  } catch (error) {
    console.error("Reaction Reward Error:", error);
  }
}

/**
 * 🚀 Handle Interaction Menu
 */
async function handleInteractionMenu(chat_id: number, message_id: number) {
  const text = `🚀 **مركز التفاعل والمكافآت** 🚀

كن عضواً فعالاً في مجتمع رويال دور واكسب النقاط الملكية تلقائياً!

🔥 **طرق التفاعل والربح:**
• **القنوات الممولة:** انضم للقنوات الجديدة = **5 نقاط**.
• **قناة التلغرام:** تفاعل مع أي منشور = **1 نقطة**.
• **تيك توك:** تفاعل مع الفيديوهات الجديدة = **1 نقطة**.

🎯 *سيقوم البوت بالتحقق من تفاعلك ومنحك النقاط فوراً!*`;

  const keyboard = {
    inline_keyboard: [
      [{ text: "📢 قنوات ومجموعات ممولة (+5)", callback_data: "promoted_list" }],
      [{ text: "📢 اذهب للقناة وتفاعل", url: "https://t.me/royaldur" }],
      [{ text: "📱 اذهب للتيك توك", url: "https://www.tiktok.com/@royaldoor86?_r=1&_t=ZS-97mjK6ikg9Y" }],
      [{ text: "⬅️ الرجوع", callback_data: "back_to_menu" }],
    ],
  };

  await editMessage(chat_id, message_id, text, keyboard);
}
/**
 * 📱 Handle Social Media Share Info
 */
async function handleShareSMInfo(chat_id: number) {
  const smInviteLink = `https://t.me/royaldoor_bot?start=sm_${chat_id}`;
  const text = `📱 **طريقة المشاركة عبر السوشل ميديا** 🚀

1️⃣ قم بنسخ رابطك الخاص أدناه.
2️⃣ انشره في فيديوهاتك على تيك توك، منشورات فيسبوك، أو حالات واتساب.
3️⃣ كل شخص يدخل للبوت ويضغط **Start** عن طريق رابطك، ستحصل أنت فوراً على **5 نقاط ملكية**! 💎

🔗 **رابطك الخاص:**
\`${smInviteLink}\`

💡 *نصيحة: اجعل منشورك جذاباً لزيادة عدد المنضمين!*`;

  await sendMessage(chat_id, text);
}

/**
 * 📢 Handle Promoted Channels List (The cycle of funding)
 */
async function handlePromotedList(chat_id: number, message_id: number) {
  try {
    const promotedSnapshot = await db.collection("funding_requests")
      .where("status", "==", "processing")
      .limit(10)
      .get();

    let text = `📢 **القنوات والمجموعات الممولة** 🚀\n\n`;
    text += `انضم لهذه القنوات لدعم المجتمع والحصول على نقاط مجانية! ✨\n\n`;

    const buttons: any[] = [];

    if (promotedSnapshot.empty) {
      text += "✨ لا توجد قنوات ممولة حالياً. كن أول من يمول قناته!";
    } else {
      promotedSnapshot.docs.forEach((doc, index) => {
        const data = doc.data();
        text += `${index + 1}️⃣ **دعم مجتمعي**\n💰 ستحصل على نقاط عند الانضمام والتحقق.\n\n`;
        buttons.push([{ text: `📢 انضم للقناة ${index + 1}`, url: data.channelLink }]);
        buttons.push([{ text: `🔍 تحقق من الانضمام (+5)`, callback_data: `verify_p_${doc.id}` }]);
      });
    }

    const keyboard = {
      inline_keyboard: [
        ...buttons,
        [{ text: "⬅️ الرجوع", callback_data: "interaction_menu" }],
      ],
    };

    await editMessage(chat_id, message_id, text, keyboard);
  } catch (error) {
    console.error("Promoted List Error:", error);
  }
}

/**
 * 📜 Handle Operation History (With Pagination)
 */
async function handleHistory(chat_id: number, message_id: number, offset: number = 0) {
  try {
    const limit = 10;
    const historySnapshot = await db.collection("telegram_users").doc(chat_id.toString())
      .collection("history")
      .orderBy("timestamp", "desc")
      .limit(limit + 1) // Fetch one extra to see if there is a next page
      .offset(offset)
      .get();

    let text = `📜 <b>سجل العمليات الملكي</b> 📜\n\n`;

    if (historySnapshot.empty) {
      text += "✨ لا توجد عمليات مسجلة حالياً.";
    } else {
      const docs = historySnapshot.docs.slice(0, limit);
      docs.forEach((doc, index) => {
        const data = doc.data();
        const typeText = data.type === "daily_harvest" ? "🎁 حصد مكافأة" :
                        data.type === "transfer_sent" ? "🤝 تحويل صادر" :
                        data.type === "transfer_received" ? "📥 تحويل وارد" : "⚙️ عملية نظام";

        text += `${offset + index + 1}️⃣ <b>${typeText}</b>\n💰 القيمة: <code>${data.amount || data.pointsGained || 0}</code> | 📅 ${data.timestamp?.toDate().toLocaleDateString('ar-EG')}\n\n`;
      });
    }

    const buttons = [];
    const navButtons = [];
    if (offset > 0) navButtons.push({ text: "⬅️ السابق", callback_data: `history_next_${offset - limit}` });
    if (historySnapshot.size > limit) navButtons.push({ text: "التالي ➡️", callback_data: `history_next_${offset + limit}` });

    if (navButtons.length > 0) buttons.push(navButtons);
    buttons.push([{ text: "⬅️ الرجوع", callback_data: "account_menu" }]);

    const keyboard = { inline_keyboard: buttons };
    await editMessage(chat_id, message_id, text, keyboard);
  } catch (error) {
    console.error("History Error:", error);
  }
}

/**
 * 👑 Agency Establishment Start
 */
async function handleCreateAgencyStart(chat_id: number) {
  const userDoc = await db.collection("telegram_users").doc(chat_id.toString()).get();
  const userData = userDoc.data();
  const cost = 1000000;

  if (!userData?.app_uid) {
    await sendMessage(chat_id, "❌ **يجب ربط حسابك بالتطبيق أولاً** لتتمكن من تأسيس وكالة.");
    return;
  }

  if ((userData?.points || 0) < cost) {
    await sendMessage(chat_id, `❌ **نقاطك غير كافية!**\n\nتأسيس وكالة (بيت دعم ملكي) يتطلب \`${cost}\` نقطة.\nرصيدك الحالي: \`${userData?.points || 0}\` نقطة.`);
    return;
  }

  const text = `👑 **تأسيس بيت دعم ملكي (وكالة)** 👑

سعر التأسيس: **1,000,000 نقطة ملكية**

عند إتمام الطلب، سيتم خصم النقاط وإرسال طلبك للإدارة. بمجرد الموافقة، ستظهر وكالتك في قائمة الوكلاء الرسميين.

هل ترغب في المتابعة؟ يرجى إرسال **اسم الوكالة** المقترح:`;

  await db.collection("telegram_users").doc(chat_id.toString()).update({
    user_state: "waiting_for_agency_name"
  });

  await sendMessage(chat_id, text);
}

/**
 * 🏠 Create Family Start
 */
async function handleCreateFamilyStart(chat_id: number) {
  const userDoc = await db.collection("telegram_users").doc(chat_id.toString()).get();
  const userData = userDoc.data();
  const cost = 100000;

  if (!userData?.app_uid) {
    await sendMessage(chat_id, "❌ يجب ربط حسابك بالتطبيق أولاً لتأسيس عائلة.");
    return;
  }

  if ((userData?.points || 0) < cost) {
    await sendMessage(chat_id, `❌ **نقاطك غير كافية!**\n\nتأسيس عائلة ملكية جديدة يتطلب \`${cost}\` نقطة.\nرصيدك الحالي: \`${userData?.points || 0}\` نقطة.`);
    return;
  }

  const text = `👨‍👩‍👧‍👦 **تأسيس عائلة ملكية جديدة** 👨‍👩‍👧‍👦

سعر التأسيس: **100,000 نقطة ملكية**

سيتم خصم النقاط وتفعيل عائلتك فوراً في التطبيق والبوت.

يرجى إرسال **اسم العائلة**:`;

  await db.collection("telegram_users").doc(chat_id.toString()).update({
    user_state: "waiting_for_family_name"
  });

  await sendMessage(chat_id, text);
}
/**
 * 🤝 Join Agency List
 */
async function handleJoinAgencyList(chat_id: number, message_id: number) {
  const agencies = await db.collection("agencies").where("isActive", "==", true).limit(10).get();

  let text = "🏰 **قائمة وكالات رويال دور المعتمدة** 🏰\n\nاختر الوكالة التي تود الانضمام إليها:";
  const buttons: any[] = [];

  agencies.docs.forEach(doc => {
    const data = doc.data();
    buttons.push([{ text: `🤝 انضمام لـ ${data.name}`, callback_data: `join_ag_${doc.id}` }]);
  });

  const keyboard = {
    inline_keyboard: [
      ...buttons,
      [{ text: "⬅️ الرجوع", callback_data: "agencies_menu" }]
    ]
  };

  await editMessage(chat_id, message_id, text, keyboard);
}

/**
 * 👨‍👩‍👧‍👦 Join Family List
 */
async function handleJoinFamilyList(chat_id: number, message_id: number) {
  const families = await db.collection("families").limit(10).get();

  let text = "👨‍👩‍👧‍👦 **عوائل رويال دور في التطبيق** 👨‍👩‍👧‍👦\n\nتواصل مع العائلات وانضم لأقوى المجتمعات:";
  const buttons: any[] = [];

  families.docs.forEach(doc => {
    const data = doc.data();
    buttons.push([{ text: `🏰 عائلة ${data.name}`, callback_data: `view_fam_${doc.id}` }]);
  });

  const keyboard = {
    inline_keyboard: [
      ...buttons,
      [{ text: "👑 تأسيس عائلة جديدة", callback_data: "create_family_start" }],
      [{ text: "⬅️ الرجوع", callback_data: "agencies_menu" }]
    ]
  };

  await editMessage(chat_id, message_id, text, keyboard);
}

async function handleAgents(chat_id: number, message_id: number) {
  const text = `🏰 **وكلاء محافظات Royal Door** 🏰

اختر الوكيل الأقرب إليك للتواصل المباشر:

🏛 **وكيل العاصمة بغداد** (أبو اسحاق المالكي)
🌆 **وكيل المنطقة الوسطى** (بغداد وما حولها)
🌴 **وكيل المنطقة الجنوبية** (البصرة والفرات الأوسط)
🌊 **وكيل المنطقة الشمالية** (كوردستان والموصل)
🏜 **وكيل المنطقة الغربية** (الأنبار وصلاح الدين)`;

  const keyboard = {
    inline_keyboard: [
      // وكيل العاصمة بغداد
      [{ text: "🏛 وكيل العاصمة بغداد (أبو اسحاق)", callback_data: "none" }],
      [
        { text: "🟢 واتساب", url: "https://wa.me/9647739676609" },
        { text: "🔵 تلغرام", url: "https://t.me/+9647739676609" }
      ],
      // المنطقة الوسطى
      [{ text: "🌆 وكيل المنطقة الوسطى", callback_data: "none" }],
      [
        { text: "🟢 واتساب", url: "https://wa.me/9647813431076" },
        { text: "🔵 تلغرام", url: "https://t.me/+9647813431076" }
      ],
      // المنطقة الجنوبية
      [{ text: "🌴 وكيل المنطقة الجنوبية", callback_data: "none" }],
      [
        { text: "🟢 واتساب", url: "https://wa.me/9647717901796" },
        { text: "🔵 تلغرام", url: "https://t.me/+9647717901796" }
      ],
      // المنطقة الشمالية
      [{ text: "🌊 وكيل المنطقة الشمالية", callback_data: "none" }],
      [
        { text: "🟢 واتساب", url: "https://wa.me/9647855900447" },
        { text: "🔵 تلغرام", url: "https://t.me/+9647855900447" }
      ],
      // المنطقة الغربية
      [{ text: "🏜 وكيل المنطقة الغربية", callback_data: "none" }],
      [
        { text: "🟢 واتساب", url: "https://wa.me/9647770992966" },
        { text: "🔵 تلغرام", url: "https://t.me/+9647770992966" }
      ],
      [{ text: "⬅️ الرجوع", callback_data: "back_to_menu" }],
    ],
  };

  await editMessage(chat_id, message_id, text, keyboard);
}

/**
 * 🏆 Handle Leaderboard (Royal Ranks)
 */
async function handleLeaderboard(chat_id: number, message_id: number, category: string = "interactions") {
  let text = "";
  let query: any;

  if (category === "interactions") {
    text = "🏆 **فرسان التفاعل - الأكثر نشاطاً** 🏆\n\n";
    query = db.collection("telegram_users").orderBy("collective_points", "desc").limit(10);
  } else if (category === "donors") {
    text = "💎 **كبار الممولين - نخبة رويال** 💎\n\n";
    query = db.collection("users").orderBy("totalSpent", "desc").limit(10);
  } else {
    text = "👥 **صنّاع المجتمع - الأكثر دعوة** 👥\n\n";
    query = db.collection("telegram_users").orderBy("referrals", "desc").limit(10);
  }

  try {
    const snapshot = await query.get();
    const buttons: any[] = [];

    if (snapshot.empty) {
      text += "✨ القائمة فارغة حالياً. كن أول من يتصدر!";
    } else {
      snapshot.docs.forEach((doc: any, index: number) => {
        const data = doc.data();
        const name = data.first_name || data.displayName || data.name || "مستخدم ملكي";
        const val = category === "interactions" ? (data.collective_points || 0) :
                    category === "donors" ? (data.totalSpent || 0) : (data.referrals || 0);
        const unit = category === "interactions" ? "نقطة" : category === "donors" ? "جوهرة" : "دعوة";

        const medal = index === 0 ? "🥇" : index === 1 ? "🥈" : index === 2 ? "🥉" : "👑";
        text += `${medal} ${index + 1}. **${name}** — \`${val}\` ${unit}\n`;

        // Add button to view profile if it's a telegram user
        if (data.telegram_id) {
          buttons.push([{ text: `👤 عرض بروفايل ${name}`, callback_data: `view_p_${data.telegram_id}` }]);
        }
      });
    }

    const keyboard = {
      inline_keyboard: [
        ...buttons.slice(0, 5), // Show top 5 buttons to avoid huge keyboard
        [
          { text: "🔥 التفاعل", callback_data: "leaderboard_interactions" },
          { text: "💎 التمويل", callback_data: "leaderboard_donors" },
          { text: "👥 الدعوات", callback_data: "leaderboard_referrals" }
        ],
        [{ text: "⬅️ الرجوع", callback_data: "back_to_menu" }],
      ],
    };

    await editMessage(chat_id, message_id, text, keyboard);
  } catch (error) {
    console.error("Leaderboard Error:", error);
    await editMessage(chat_id, message_id, "❌ حدث خطأ أثناء جلب لوحة المتصدرين.");
  }
}

/**
 * 👤 View Public Profile Card
 */
async function handleViewPublicProfile(chat_id: number, targetUserId: string) {
  try {
    const userDoc = await db.collection("telegram_users").doc(targetUserId).get();
    if (!userDoc.exists) {
      await sendMessage(chat_id, "❌ تعذر العثور على بيانات هذا المستخدم.");
      return;
    }

    const data = userDoc.data()!;
    const name = data.first_name || "مستخدم ملكي";
    const vip = data.is_vip ? (data.vip_type === "platinum" ? "💎 بلاتيني" : "⭐ VIP") : "عضو عادي";

    const profileCard = `👤 **الملف الشخصي الملكي** 👑

✨ **الاسم:** ${name}
🏆 **المستوى:** ${vip}
💎 **إجمالي النقاط:** \`${data.points || 0}\`
🚀 **نقاط التفاعل:** \`${data.collective_points || 0}\`
👥 **عدد الإحالات:** \`${data.referrals || 0}\`

━━━━━━━━━━━━
🌟 *عضو مميز في مجتمع رويال دور*`;

    await sendMessage(chat_id, profileCard);
  } catch (error) {
    console.error("View Profile Error:", error);
  }
}
async function handleStats(chat_id: number, message_id: number) {
  const userDoc = await db.collection("telegram_users").doc(chat_id.toString()).get();
  const userData = userDoc.data();

  const text = `📊 **إحصائيات حسابك الملكي** 📊

استعرض نشاطك وتفاعلك داخل منصة رويال دور:

💰 **الرصيد والنقاط:**
• إجمالي النقاط: \`${userData?.points || 0}\`
• نقاط المجمعة: \`${userData?.collective_points || 0}\`

👥 **الدعوات والإحالات:**
• الأصدقاء المدعوون: \`${userData?.referrals || 0}\`
• نقاط الإحالة: \`${(userData?.referrals || 0) * 2}\`

🔥 **التفاعل والنشاط:**
• عدد التفاعلات (Reactions): \`${userData?.interactions_count || 0}\`
• المكافآت اليومية المستلمة: \`${userData?.harvests_count || 0}\`

🏆 **الترتيب والمستوى:**
• مستوى العضوية: \`${userData?.is_vip ? "VIP" : "عضو عادي"}\`
• ترتيبك الحالي: **يتم التحديث...**`;

  const keyboard = {
    inline_keyboard: [
      [{ text: "🏆 لوحة المتصدرين", callback_data: "leaderboard" }],
      [{ text: "⬅️ الرجوع", callback_data: "back_to_menu" }],
    ],
  };

  await editMessage(chat_id, message_id, text, keyboard);
}

/**
 * 💎 Handle Buy Upgrade Points Menu
 */
async function handleBuyPointsMenu(chat_id: number, message_id: number) {
  const text = `💎 <b>شراء النقاط الملكية</b> 💎

يمكنك شراء النقاط لاستخدامها في متجر الأيديات، تمويل القنوات، أو ترقية عضويتك.

💰 <b>أسعار الشحن الرسمية:</b>
• 10,000 نقطة = <b>10,000 دينار عراقي</b>
• 25,000 نقطة = <b>25,000 دينار عراقي</b>
• 50,000 نقطة = <b>50,000 دينار عراقي</b>

🔄 <b>معدل التحويل:</b> 100 نقطة = 10 جواهر في التطبيق.

اختر الكمية المطلوبة للشحن عبر الوكيل المعتمد:`;

  const keyboard = {
    inline_keyboard: [
      [{ text: "💎 10,000 نقطة (10,000 د.ع)", callback_data: "agents" }],
      [{ text: "💎 50,000 نقطة (50,000 د.ع)", callback_data: "agents" }],
      [{ text: "🔄 تحويل نقاط لـ جواهر (100ن = 10ج)", callback_data: "convert_to_app_gems" }],
      [{ text: "⬅️ الرجوع للقائمة", callback_data: "back_to_menu" }],
    ],
  };

  await editMessage(chat_id, message_id, text, keyboard);
}

/**
 * 🔓 Handle Membership Upgrade Logic
 */
async function handleUpgradeLogic(chat_id: number) {
  const userRef = db.collection("telegram_users").doc(chat_id.toString());
  const userDoc = await userRef.get();
  const points = userDoc.data()?.points || 0;
  const currentVip = userDoc.data()?.vip_type || "none";

  let targetVip = "";
  let requiredPoints = 0;

  // Determine next level
  if (currentVip === "none") { targetVip = "bronze"; requiredPoints = 50000; }
  else if (currentVip === "bronze") { targetVip = "silver"; requiredPoints = 75000; }
  else if (currentVip === "silver") { targetVip = "gold"; requiredPoints = 100000; }
  else if (currentVip === "gold") { targetVip = "platinum"; requiredPoints = 150000; }
  else {
    await sendMessage(chat_id, "👑 أنت تمتلك بالفعل أعلى مستوى عضوية (بلاتيني)!");
    return;
  }

  if (points < requiredPoints) {
    await sendMessage(chat_id, `❌ **عذراً، لا يمكنك الترقية الآن!**\n\nتحتاج إلى \`${requiredPoints}\` نقطة للوصول إلى المستوى التالي.\nرصيدك الحالي: \`${points}\` نقطة.`);
    return;
  }

  try {
    await db.runTransaction(async (transaction) => {
      transaction.update(userRef, {
        points: admin.firestore.FieldValue.increment(-requiredPoints),
        is_vip: true,
        vip_type: targetVip,
        upgraded_at: admin.firestore.FieldValue.serverTimestamp()
      });

      // Update linked App User if exists
      const appUid = userDoc.data()?.app_uid;
      if (appUid) {
        transaction.update(db.collection("users").doc(appUid), {
          "vip_status.level": targetVip,
          "vip_status.activatedAt": admin.firestore.FieldValue.serverTimestamp()
        });
      }
    });

    const vipNames: any = { bronze: "برونزي 🥉", silver: "فضي 🥈", gold: "ذهبي 🥇", platinum: "بلاتيني 💎" };
    await sendMessage(chat_id, `🎉 **تم التفعيل بنجاح!** 🎉\n\nمبروك! لقد تمت ترقية حسابك إلى المستوى **${vipNames[targetVip]}**. تمتع بمميزاتك الجديدة الآن.`);
  } catch (error) {
    console.error("Upgrade Error:", error);
    await sendMessage(chat_id, "❌ حدث خطأ أثناء الترقية. حاول مرة أخرى لاحقاً.");
  }
}
/**
 * 🤝 Handle Joining an Agency
 */
async function handleJoinAgency(chat_id: number, agencyId: string) {
  const userRef = db.collection("telegram_users").doc(chat_id.toString());
  const userDoc = await userRef.get();
  const appUid = userDoc.data()?.app_uid;

  if (!appUid) {
    await sendMessage(chat_id, "❌ يجب ربط حسابك بالتطبيق أولاً للانضمام لوكالة.");
    return;
  }

  try {
    const agencyRef = db.collection("agencies").doc(agencyId);
    const agencyDoc = await agencyRef.get();

    if (!agencyDoc.exists) throw new Error("Agency not found");

    await db.runTransaction(async (transaction) => {
      // 1. Update User in App
      transaction.update(db.collection("users").doc(appUid), {
        agencyId: agencyId
      });

      // 2. Add to Agency Members sub-collection
      const memberRef = agencyRef.collection("members").doc(appUid);
      transaction.set(memberRef, {
        uid: appUid,
        joinedAt: admin.firestore.FieldValue.serverTimestamp()
      });

      // 3. Increment agency member count
      transaction.update(agencyRef, {
        memberCount: admin.firestore.FieldValue.increment(1)
      });
    });

    await sendMessage(chat_id, `✅ **تم الانضمام لوكالة (${agencyDoc.data()?.name}) بنجاح!** 🏰\n\nأهلاً بك في الفريق الجديد. يمكنك الآن رؤية تفاصيل وكالتك داخل التطبيق.`);
  } catch (error) {
    console.error("Join Agency Error:", error);
    await sendMessage(chat_id, "❌ حدث خطأ أثناء محاولة الانضمام للوكالة.");
  }
}

/**
 * 👨‍👩‍👧‍👦 View Family Details
 */
async function handleViewFamily(chat_id: number, familyId: string) {
  const familyDoc = await db.collection("families").doc(familyId).get();
  if (!familyDoc.exists) return;

  const data = familyDoc.data()!;
  const text = `🏰 **عائلة: ${data.name}** 🏰

✨ **الشعار:** ${data.slogan || "لا يوجد"}
👥 **الأعضاء:** ${data.memberCount}/${data.maxMembers}
⭐ **المستوى:** ${data.level}
🛡️ **حالة التوثيق:** ${data.isVerified ? "موثقة ✅" : "غير موثقة"}

━━━━━━━━━━━━
🌟 *انضم الآن وكن جزءاً من أقوى عوائل رويال دور!*`;

  const keyboard = {
    inline_keyboard: [
      [{ text: "🤝 طلب انضمام للعائلة", callback_data: `join_fam_exec_${familyId}` }],
      [{ text: "⬅️ رجوع للقائمة", callback_data: "join_family" }]
    ]
  };

  await sendMessage(chat_id, text, keyboard);
}

/**
 * ✅ Execute Family Joining
 */
async function handleJoinFamilyExecute(chat_id: number, familyId: string) {
  const userRef = db.collection("telegram_users").doc(chat_id.toString());
  const userDoc = await userRef.get();
  const appUid = userDoc.data()?.app_uid;

  if (!appUid) {
    await sendMessage(chat_id, "❌ يجب ربط حسابك بالتطبيق أولاً للانضمام لعائلة.");
    return;
  }

  try {
    const familyRef = db.collection("families").doc(familyId);
    const appUserRef = db.collection("users").doc(appUid);

    await db.runTransaction(async (transaction) => {
      const uDoc = await transaction.get(appUserRef);
      if (uDoc.data()?.familyId) throw new Error("Already in family");

      transaction.update(appUserRef, { familyId: familyId, familyRole: "member" });
      transaction.update(familyRef, { memberCount: admin.firestore.FieldValue.increment(1) });

      const memberRef = familyRef.collection("members").doc(appUid);
      transaction.set(memberRef, {
        uid: appUid,
        role: "member",
        joinedAt: admin.firestore.FieldValue.serverTimestamp()
      });
    });

    await sendMessage(chat_id, "✅ **مبروك! تم انضمامك للعائلة بنجاح.** 👨‍👩‍👧‍👦\n\nيمكنك الآن التفاعل مع أفراد عائلتك داخل التطبيق.");
  } catch (error: any) {
    if (error.message === "Already in family") {
      await sendMessage(chat_id, "⚠️ أنت منضم لعائلة بالفعل في التطبيق!");
    } else {
      await sendMessage(chat_id, "❌ حدث خطأ أثناء الانضمام للعائلة.");
    }
  }
}
async function handleCoupons(chat_id: number, message_id: number) {
  const text = `<b>🎫 نظام البطاقات الملكية</b>\n\nاختر البطاقة التي ترغب في استعراض تقدمك فيها أو استلامها:`;

  const keyboard = {
    inline_keyboard: [
      [{ text: "🥉 البطاقة البرونزية", callback_data: "view_coupon_bronze" }],
      [{ text: "🥈 البطاقة الفضية", callback_data: "view_coupon_silver" }],
      [{ text: "🥇 البطاقة الذهبية", callback_data: "view_coupon_gold" }],
      [{ text: "⬅️ الرجوع للقائمة", callback_data: "back_to_menu" }]
    ]
  };

  await editMessage(chat_id, message_id, text, keyboard);
}

/**
 * 🃏 View Specific Coupon Card with Image and Progress
 */
async function handleViewCouponCard(chat_id: number, message_id: number, type: string) {
  try {
    const userDoc = await db.collection("telegram_users").doc(chat_id.toString()).get();
    const userData = userDoc.data();

    const points = userData?.points || 0;
    const referrals = userData?.referrals || 0;

    let title = "";
    let description = "";
    let condition = "";
    let currentVal = 0;
    let targetVal = 0;
    let icon = "";

    if (type === "bronze") {
      title = "البطاقة البرونزية";
      description = "صالحة لفتح أي ميزة في المتجر لمرة واحدة واستخدام واحد فقط.";
      condition = "الوصول لـ 10,000,000 نقطة.";
      targetVal = 10000000;
      currentVal = points;
      icon = "🥉";
    } else if (type === "silver") {
      title = "البطاقة الفضية";
      description = "تمنحك إنشاء عائلة مجانية تماماً أو مميزات ID + 10 نقاط مستوى.";
      condition = "دعوة 100 صديق للبوت.";
      targetVal = 100;
      currentVal = referrals;
      icon = "🥈";
    } else {
      title = "البطاقة الذهبية";
      description = "أضف 250 عضو للقناة واحصل على هذا الكوبون لفتح أي ميزة.";
      condition = "دعوة 250 عضو (إحالات).";
      targetVal = 250;
      currentVal = referrals;
      icon = "🥇";
    }

    const percentage = Math.min((currentVal / targetVal) * 100, 100).toFixed(1);
    const filled = Math.floor(parseFloat(percentage) / 10);
    const progressBar = "▓".repeat(filled) + "░".repeat(10 - filled);

    const cardDesign = `
━━━━━━━━━━━━━━
  ${icon} <b>${title}</b> ${icon}
━━━━━━━━━━━━━━

${description}

🎯 <b>الشرط:</b> ${condition}
📊 <b>التقدم:</b> [<code>${progressBar}</code>] ${percentage}%
💰 <b>الحالة:</b> <code>${currentVal.toLocaleString()}</code> / <code>${targetVal.toLocaleString()}</code>

━━━━━━━━━━━━━━
${currentVal >= targetVal ? "✅ <b>البطاقة متاحة للاستلام الآن!</b>" : "⏳ <b>استمر في التفاعل لتحقيق الهدف</b>"}
    `;

    const buttons = [];
    if (currentVal >= targetVal) {
      buttons.push([{ text: `🎁 استلام ${title}`, callback_data: `claim_coupon_${type}` }]);
    }
    buttons.push([{ text: "⬅️ الرجوع للكوبونات", callback_data: "coupons" }]);

    const keyboard = { inline_keyboard: buttons };

    await editMessage(chat_id, message_id, cardDesign, keyboard);

  } catch (error) {
    console.error("View Card Error:", error);
  }
}

async function verifyPromotedJoin(chat_id: number, requestId: string) {
  const userRef = db.collection("telegram_users").doc(chat_id.toString());
  const userDoc = await userRef.get();

  if (userDoc.data()?.completed_promoted?.includes(requestId)) {
    await sendMessage(chat_id, "⚠️ لقد حصلت على نقاط هذه القناة مسبقاً!");
    return;
  }

  const requestDoc = await db.collection("funding_requests").doc(requestId).get();
  if (!requestDoc.exists) return;

  await userRef.update({
    points: admin.firestore.FieldValue.increment(5),
    completed_promoted: admin.firestore.FieldValue.arrayUnion(requestId)
  });

  await sendMessage(chat_id, `✅ تم التحقق بنجاح! حصلت على **5 نقاط** ملكية.`);
}

/**
 * 🎁 Handle Coupon Claiming
 */
async function handleClaimCoupon(chat_id: number, type: string) {
  try {
    const userRef = db.collection("telegram_users").doc(chat_id.toString());
    const userDoc = await userRef.get();
    const userData = userDoc.data();

    let isEligible = false;
    let typeName = "";

    if (type === "bronze" && (userData?.points || 0) >= 10000000) { isEligible = true; typeName = "البرونزية 🥉"; }
    else if (type === "silver" && (userData?.referrals || 0) >= 100) { isEligible = true; typeName = "الفضية 🥈"; }
    else if (type === "gold" && (userData?.referrals || 0) >= 250) { isEligible = true; typeName = "الذهبية 🥇"; }

    if (!isEligible) {
      await sendMessage(chat_id, "❌ <b>عذراً!</b> لم تحقق شروط هذه البطاقة بعد.");
      return;
    }

    // Check if already claimed
    const claimCheck = await db.collection("claimed_coupons")
      .where("userId", "==", chat_id)
      .where("type", "==", type)
      .get();

    if (!claimCheck.empty) {
      const existingCode = claimCheck.docs[0].data().code;
      await sendMessage(chat_id, `⚠️ <b>لقد استلمت هذه البطاقة مسبقاً!</b>\n\nكود التفعيل الخاص بك: <code>${existingCode}</code>`);
      return;
    }

    // Generate Secret Serial
    const serial = "RD-" + Math.random().toString(36).substring(2, 8).toUpperCase();

    await db.collection("claimed_coupons").add({
      userId: chat_id,
      type: type,
      code: serial,
      claimedAt: admin.firestore.FieldValue.serverTimestamp(),
      status: "pending"
    });

    const cardDesign = `
👑 <b>بطاقة رويال دور الملكية (${typeName})</b> 👑

تهانينا! لقد حققت الإنجاز وتم إصدار بطاقتك بنجاح.

💎 <b>الشركة:</b> رويال دور (Royal Door)
🔑 <b>كود التفعيل السري:</b> <code>${serial}</code>
📅 <b>تاريخ الإصدار:</b> ${new Date().toLocaleDateString('ar-EG')}

⚠️ <b>تعليمات التفعيل:</b>
اضغط على الزر أدناه لمراسلة المدير وإرسال الكود له ليقوم بتفعيل الميزات في حسابك داخل التطبيق فوراً.
    `;

    const keyboard = {
      inline_keyboard: [
        [{ text: "👨‍💼 مراسلة المدير لتفعيل البطاقة", url: "https://t.me/royal9door" }],
        [{ text: "⬅️ العودة للقائمة", callback_data: "back_to_menu" }]
      ]
    };

    await sendMessage(chat_id, cardDesign, keyboard);
  } catch (error) {
    console.error("Claim Error:", error);
  }
}

async function sendMessage(chat_id: number, text: string, keyboard: any = null) {
  try {
    const payload: any = {
      chat_id,
      text,
      parse_mode: "HTML" // Changed to HTML for better stability
    };
    if (keyboard) {
      payload.reply_markup = keyboard;
    }
    await axios.post(`${TELEGRAM_API}/sendMessage`, payload);
  } catch (error: any) {
    console.error("Error sending message to", chat_id, ":", error?.response?.data || error.message);
  }
}

/**
 * ✏️ Edit Message
 */
async function editMessage(
  chat_id: number,
  message_id: number,
  text: string,
  keyboard: any = null
) {
  try {
    await axios.post(`${TELEGRAM_API}/editMessageText`, {
      chat_id,
      message_id,
      text,
      parse_mode: "HTML",
      reply_markup: keyboard,
    });
  } catch (error: any) {
    console.error("Error editing message:", error?.response?.data || error.message);
  }
}

/**
 * ⚙️ Handle Command
 */
async function handleCommand(chat_id: number, command: string, user: any) {
  let text = "";

  switch (command) {
    case "/balance":
      text = "💎 رصيدك: 2,850 نقطة";
      break;
    case "/profile":
      text = `👤 **حسابك**\nالاسم: ${user?.first_name}\nالمستوى: 1`;
      break;
    case "/stats":
      text = `📊 **الإحصائيات**\nالنقاط: 2,850\nالألعاب: 42`;
      break;
    default:
      text = "❓ أمر غير معروف. اكتب /start للقائمة الرئيسية";
  }

  await sendMessage(chat_id, text);
}
