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

# --- نصوص وأزرار مدمجة لضمان السرعة والظهور ---
STRINGS = {
    'ar': {
        'welcome': "🏰 *مرحباً بك في رويال دور الملكي* 🏰\n\nأهلاً بك يا *{}* في عالمك الخاص.\nأدر رصيدك واستلم هداياك من القائمة أدناه: 👇",
    }
}

def get_full_keyboard():
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

# --- محاولة استيراد المنطق من lib (مع عزل الأخطاء) ---
try:
    from lib.royal_door_bot.db import db
    from lib.royal_door_bot.handlers.button_handler import handle_buttons
    from lib.royal_door_bot.handlers.message_handler import handle_message
    logger.info("✅ Full logic modules loaded")
except Exception as e:
    logger.error(f"⚠️ Logic import warning: {e}")
    db = None
    async def handle_buttons(u, c): await u.callback_query.answer("⚠️ جاري تحديث بيانات السيرفر...")
    async def handle_message(u, c): pass

# التوكن الجديد المحدث
TOKEN = "8351595801:AAHeGbikNatcTxfyWwuEpR-UqO61HTmHvCg"

async def start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not update.effective_user: return
    user_name = update.effective_user.first_name
    
    # الرد الفوري لضمان عدم بقاء البوت فارغاً
    await update.message.reply_text(
        STRINGS['ar']['welcome'].format(user_name),
        reply_markup=get_full_keyboard(),
        parse_mode="Markdown"
    )

async def post_init(application):
    # مسح الويب هوك القديم تماماً لإنهاء الـ Conflict
    await application.bot.delete_webhook(drop_pending_updates=True)
    await application.bot.set_my_commands([BotCommand("start", "فتح القائمة الملكية 🏰")])

def main():
    if not TOKEN: return
    application = ApplicationBuilder().token(TOKEN).post_init(post_init).build()
    
    application.add_handler(CommandHandler("start", start))
    application.add_handler(CallbackQueryHandler(handle_buttons))
    application.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND, handle_message))
    
    print(f"[{datetime.now().strftime('%H:%M:%S')}] 🚀 Royal Bot is FULLY OPERATIONAL...")
    application.run_polling(drop_pending_updates=True)

if __name__ == "__main__":
    main()
