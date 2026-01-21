# core.py
from telegram import InlineKeyboardButton, InlineKeyboardMarkup, WebAppInfo, ForceReply

STRINGS = {
    'ar': {
        'welcome': (
            "✨ *مرحباً بك في رويال دور - البوابة الملكية* ✨\n\n"
            "أهلاً بك يا *{}* في عالمك الخاص حيث تتحول نقاطك إلى مكافآت حقيقية. 🏰\n\n"
            "🌟 *اكتشف عالمنا الحصري:*\n"
            "🎁 *هدايا ذكية:* نقاط متزايدة في انتظارك يومياً.\n"
            "🔄 *تحويل ملكي:* حوّل نقاطك إلى جواهر وكوينز فوراً.\n"
            "🎡 *عجلة الحظ:* تحدّ حظك واربح حتى 500 نقطة.\n"
            "👥 *دعوة الأصدقاء:* ابنِ فريقك الملكي واربح 50 نقطة عن كل صديق.\n\n"
            "👑 *ابدأ الآن وأدر رصيدك من القائمة أدناه:* 👇"
        ),
        'back': "🔙 عودة للقائمة الرئيسية",
        'profile': "👤 *ملفك الملكي*\n\n👑 الاسم: {}\n🆔 الآيدي: `{}`\n✨ النقاط: `{}`\n💎 الجواهر: `{}`",
        'daily_ok': "🎉 حصلت على {} نقطة ملكية!",
        'daily_wait': "⏳ عد غداً لاستلام هديتك!",
        'tasks_title': "✨ *المهام الاجتماعية*\nتابعنا واحصل على 10 نقاط لكل مهمة!",
        'agents': "🤝 *وكلاء رويال دور*\nسيتم تفعيل هذا القسم قريباً لعرض الوكلاء المعتمدين.",
        'link_start': "🆔 *يرجى إرسال الآيدي الملكي الخاص بك لربط الحساب:*",
        'not_linked': "⚠️ يرجى ربط حسابك أولاً.",
        'conv_title': "🔄 *تحويل النقاط الملكية*\n\n💰 رصيدك الحالي: *{}* نقطة ✨\n\n• 100 نقطة ⬅️ 10 جواهر 💎\n• 50 نقطة ⬅️ 10 كوينز 🪙",
        'conv_ok': "✅ تم التحويل بنجاح وتحديث رصيدك!",
        'vip_title': "👑 *حالة VIP والنبلاء*\n\nرتبتك الحالية في التطبيق هي: *{}*",
        'spin_intro': "🎡 *عجلة الحظ الملكية*\nسعر اللفة: 5 نقاط.",
        'ref_msg': "👥 *نظام الإحالة*\nشارك رابطك واحصل على 50 نقطة:\n`{}`"
    }
}

def get_main_keyboard(is_linked=False):
    keyboard = [
        [InlineKeyboardButton("🎁 هدية يومية", callback_data="daily"), InlineKeyboardButton("💰 رصيدي", callback_data="profile")],
        [InlineKeyboardButton("✨ اربح نقاط مجانية", callback_data="social_tasks")],
        [InlineKeyboardButton("🛒 المتجر", web_app=WebAppInfo(url="https://royaldoor.live/store")), InlineKeyboardButton("🎡 عجلة الحظ", callback_data="spin_wheel")],
        [InlineKeyboardButton("🔄 تحويل النقاط", callback_data="convert"), InlineKeyboardButton("🏆 المتصدرين", callback_data="leaderboard")],
        [InlineKeyboardButton("👥 دعوة أصدقاء", callback_data="referral")],
        [InlineKeyboardButton("👑 حالة VIP", callback_data="vip"), InlineKeyboardButton("🤝 وكلاء رويال دور", callback_data="agents_list")]
    ]
    if not is_linked: keyboard.append([InlineKeyboardButton("🔗 ربط الحساب", callback_data="link_app")])
    keyboard.append([InlineKeyboardButton("🆘 الدعم", web_app=WebAppInfo(url="https://royaldoor.live/support"))])
    return InlineKeyboardMarkup(keyboard)
