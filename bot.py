import os
import sys
import logging
from datetime import datetime

# إعداد السجلات
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# إضافة المسارات
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
if BASE_DIR not in sys.path: sys.path.insert(0, BASE_DIR)

from telegram import Update, BotCommand, InlineKeyboardButton, InlineKeyboardMarkup, WebAppInfo
from telegram.ext import ApplicationBuilder, CommandHandler, CallbackQueryHandler, MessageHandler, filters, ContextTypes

# --- النصوص والأزرار الملكية (كاملة) ---
try:
    from lib.royal_door_bot.config import TOKEN as CONFIG_TOKEN
    from lib.royal_door_bot.core import STRINGS, get_main_keyboard
    from lib.royal_door_bot.db import db
    from lib.royal_door_bot.handlers.button_handler import handle_buttons
    from lib.royal_door_bot.handlers.start_handler import start
    from lib.royal_door_bot.handlers.message_handler import handle_message
    logger.info("✅ Core modules loaded successfully")
except Exception as e:
    logger.error(f"⚠️ Logic import warning: {e}")
    # نسخة طوارئ للأزرار
    STRINGS = {'ar': {'welcome': "🏰 *مرحباً بك في رويال دور الملكي* 🏰\n\nأهلاً بك يا *{}*.\nأدر رصيدك من القائمة أدناه: 👇"}}
    def get_main_keyboard(is_linked=True):
        return InlineKeyboardMarkup([
            [InlineKeyboardButton("🎁 هدية يومية", callback_data="daily"), InlineKeyboardButton("💰 رصيدي", callback_data="profile")],
            [InlineKeyboardButton("✨ اربح نقاط مجانية", callback_data="tasks")],
            [InlineKeyboardButton("🛒 المتجر", web_app=WebAppInfo(url="https://royaldoor.live/store")), InlineKeyboardButton("🎡 عجلة الحظ", callback_data="spin_wheel")],
            [InlineKeyboardButton("🔄 تحويل النقاط", callback_data="convert")],
            [InlineKeyboardButton("👥 دعوة أصدقاء", callback_data="referral")],
            [InlineKeyboardButton("🆘 الدعم", web_app=WebAppInfo(url="https://royaldoor.live/support"))]
        ])
    async def handle_buttons(u, c): await u.callback_query.answer("⚠️ جاري تحميل الوظائف...")
    async def handle_message(u, c): pass
    db = None

# التوكن الجديد
TOKEN = "8351595801:AAHeGbikNatcTxfyWwuEpR-UqO61HTmHvCg"

async def post_init(application):
    # مسح الويب هوك القديم تماماً لإنهاء الـ Conflict
    await application.bot.delete_webhook(drop_pending_updates=True)
    await application.bot.set_my_commands([BotCommand("start", "القائمة الملكية 🏰")])

def main():
    if not TOKEN: return
    application = ApplicationBuilder().token(TOKEN).post_init(post_init).build()
    
    application.add_handler(CommandHandler("start", start))
    application.add_handler(CallbackQueryHandler(handle_buttons))
    application.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND, handle_message))
    
    print(f"[{datetime.now().strftime('%H:%M:%S')}] 🚀 Royal Bot is FULLY ONLINE on Railway...")
    application.run_polling(drop_pending_updates=True)

if __name__ == "__main__":
    main()
