import os
import sys
import logging
import asyncio
from datetime import datetime

# إعداد السجلات
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# إضافة المسارات
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
if BASE_DIR not in sys.path: sys.path.insert(0, BASE_DIR)

from telegram import Update, BotCommand, InlineKeyboardButton, InlineKeyboardMarkup, WebAppInfo
from telegram.ext import ApplicationBuilder, CommandHandler, CallbackQueryHandler, MessageHandler, filters, ContextTypes

# --- النصوص والأزرار الملكية الكاملة (مدمجة لضمان الاستقرار) ---
STRINGS = {
    'ar': {
        'welcome': (
            "✨ *مرحباً بك في رويال دور - البوابة الملكية* ✨\n\n"
            "أهلاً بك يا *{}* في عالمك الخاص حيث تتحول نقاطك إلى مكافآت حقيقية. 🏰\n\n"
            "🌟 *اكتشف عالمنا الحصري:*\n"
            "🎁 *هدايا ذكية:* نقاط متزايدة في انتظارك يومياً.\n"
            "🔄 *تحويل ملكي:* حوّل نقاطك إلى جواهر وكوينز فوراً.\n"
            "🎡 *عجلة الحظ:* تحدّ حظك واربح حتى 500 نقطة.\n"
            "👥 *دعوة الأصدقاء:* ابنِ فريقك الملكي واربح 50 نقطة.\n\n"
            "👑 *ابدأ الآن وأدر رصيدك من القائمة أدناه:* 👇"
        ),
    }
}

def get_main_keyboard(is_linked=True):
    keyboard = [
        [InlineKeyboardButton("🎁 هدية يومية", callback_data="daily"), InlineKeyboardButton("💰 رصيدي", callback_data="profile")],
        [InlineKeyboardButton("✨ اربح نقاط مجانية", callback_data="tasks")],
        [InlineKeyboardButton("🛒 المتجر", web_app=WebAppInfo(url="https://royaldoor.live/store")), InlineKeyboardButton("🎡 عجلة الحظ", callback_data="spin_wheel")],
        [InlineKeyboardButton("🔄 تحويل النقاط", callback_data="convert"), InlineKeyboardButton("🏆 المتصدرين", callback_data="leaderboard")],
        [InlineKeyboardButton("👥 دعوة أصدقاء", callback_data="referral")],
        [InlineKeyboardButton("👑 حالة VIP", callback_data="vip"), InlineKeyboardButton("🤝 وكلاء رويال دور", callback_data="agents_list")],
        [InlineKeyboardButton("🆘 الدعم", web_app=WebAppInfo(url="https://royaldoor.live/support"))]
    ]
    return InlineKeyboardMarkup(keyboard)

# --- محاولة استيراد المنطق من lib ---
try:
    from lib.royal_door_bot.config import TOKEN as CONFIG_TOKEN
    from lib.royal_door_bot.handlers.button_handler import handle_buttons
    from lib.royal_door_bot.handlers.message_handler import handle_message
    from lib.royal_door_bot.db import db
    logger.info("✅ Core modules loaded")
except Exception as e:
    logger.error(f"⚠️ Warning: Module import error: {e}")
    db = None
    async def handle_buttons(u, c): await u.callback_query.answer("جاري تحميل الوظيفة...")
    async def handle_message(u, c): pass

# التوكن المحدث (يفضل استخدامه من متغيرات البيئة)
TOKEN = os.getenv("BOT_TOKEN") or "8351595801:AAF1UjhVKXzxoafS-nSVn2MPrpEc9pSQJ04"

async def start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not update.effective_user: return
    user_name = update.effective_user.first_name
    
    # محاولة التحقق من قاعدة البيانات للربط
    is_linked = False
    if db:
        try:
            user_id = str(update.effective_user.id)
            user_docs = db.collection('users').where('telegramId', '==', user_id).limit(1).get()
            is_linked = len(user_docs) > 0
        except: pass

    await update.message.reply_text(
        STRINGS['ar']['welcome'].format(user_name),
        reply_markup=get_main_keyboard(is_linked),
        parse_mode="Markdown"
    )

async def post_init(application):
    # مسح أي ويب هوك قديم قد يسبب تعارض
    await application.bot.delete_webhook(drop_pending_updates=True)
    await application.bot.set_my_commands([BotCommand("start", "فتح القائمة الملكية 🏰")])

def main():
    if not TOKEN: return
    application = ApplicationBuilder().token(TOKEN).post_init(post_init).build()
    
    application.add_handler(CommandHandler("start", start))
    application.add_handler(CallbackQueryHandler(handle_buttons))
    application.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND, handle_message))
    
    print("🚀 Royal Door Bot is LIVE and fully integrated...")
    application.run_polling(drop_pending_updates=True)

if __name__ == "__main__":
    main()
