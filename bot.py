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

# --- محاولة استيراد المكونات الملكية ---
try:
    from lib.royal_door_bot.config import TOKEN as CONFIG_TOKEN
    from lib.royal_door_bot.core import STRINGS, get_main_keyboard
    from lib.royal_door_bot.db import db
    from lib.royal_door_bot.handlers.button_handler import handle_buttons
    from lib.royal_door_bot.handlers.start_handler import start
    from lib.royal_door_bot.handlers.message_handler import handle_message
    logger.info("✅ Full logic integrated successfully")
except Exception as e:
    logger.error(f"⚠️ Logic import warning: {e}")
    # وظائف طوارئ
    STRINGS = {'ar': {'welcome': "🏰 أهلاً بك في رويال دور 🏰"}}
    get_main_keyboard = lambda x: InlineKeyboardMarkup([[InlineKeyboardButton("تحديث القائمة", callback_data="start")]])
    db = None

TOKEN = os.getenv("BOT_TOKEN") or "8351595801:AAF1UjhVKXzxoafS-nSVn2MPrpEc9pSQJ04"

def log_print(msg):
    print(f"[{datetime.now().strftime('%H:%M:%S')}] {msg}")
    sys.stdout.flush()

async def post_init(application):
    await application.bot.set_my_commands([BotCommand("start", "فتح القائمة الملكية 🏰")])

def main():
    if not TOKEN: return
    
    # بناء التطبيق مع خاصية مسح التعارض
    application = ApplicationBuilder().token(TOKEN).post_init(post_init).build()
    
    # ربط جميع المعالجات
    application.add_handler(CommandHandler("start", start))
    application.add_handler(CallbackQueryHandler(handle_buttons))
    application.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND, handle_message))
    
    log_print("🚀 Royal Door Bot is FULLY RESTORED and Live...")
    
    # تنظيف التحديثات القديمة لمنع الـ Conflict
    application.run_polling(drop_pending_updates=True)

if __name__ == "__main__":
    main()
