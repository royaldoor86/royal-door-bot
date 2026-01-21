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

# --- استيراد النصوص والأزرار والمنطق من ملفات المشروع ---
try:
    from lib.royal_door_bot.config import TOKEN as CONFIG_TOKEN
    from lib.royal_door_bot.core import STRINGS, get_main_keyboard
    from lib.royal_door_bot.db import db
    from lib.royal_door_bot.handlers.button_handler import handle_buttons
    from lib.royal_door_bot.handlers.start_handler import start
    from lib.royal_door_bot.handlers.message_handler import handle_message
    logger.info("✅ Full Royal Logic Loaded")
except Exception as e:
    logger.error(f"⚠️ Warning: Modules failed to load: {e}")
    STRINGS = {'ar': {'welcome': "🏰 *أهلاً بك في رويال دور الملكي* 🏰\n\nأدر رصيدك من القائمة أدناه: 👇"}}
    def get_main_keyboard(is_linked=True):
        return InlineKeyboardMarkup([
            [InlineKeyboardButton("🎁 هدية يومية", callback_data="daily"), InlineKeyboardButton("💰 رصيدي", callback_data="profile")],
            [InlineKeyboardButton("🛒 المتجر", web_app=WebAppInfo(url="https://royaldoor.live/store"))],
            [InlineKeyboardButton("🆘 الدعم", web_app=WebAppInfo(url="https://royaldoor.live/support"))]
        ])
    async def handle_buttons(u, c): await u.callback_query.answer("جاري التحميل...")
    async def handle_message(u, c): pass

# التوكن الجديد المحدث
NEW_TOKEN = "8351595801:AAHeGbikNatcTxfyWwuEpR-UqO61HTmHvCg"
TOKEN = os.getenv("BOT_TOKEN") or NEW_TOKEN

async def post_init(application):
    # مسح الويب هوك والطلبات القديمة تماماً لإنهاء الـ Conflict
    await application.bot.delete_webhook(drop_pending_updates=True)
    await application.bot.set_my_commands([BotCommand("start", "فتح القائمة الملكية 🏰")])

def main():
    if not TOKEN:
        logger.error("❌ CRITICAL: NO TOKEN FOUND!")
        return
        
    application = ApplicationBuilder().token(TOKEN).post_init(post_init).build()
    
    application.add_handler(CommandHandler("start", start))
    application.add_handler(CallbackQueryHandler(handle_buttons))
    application.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND, handle_message))
    
    print(f"[{datetime.now().strftime('%H:%M:%S')}] 🚀 Royal Bot is LIVE with NEW TOKEN...")
    
    application.run_polling(drop_pending_updates=True)

if __name__ == "__main__":
    main()
