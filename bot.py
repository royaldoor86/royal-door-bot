import os
import sys
import logging
from datetime import datetime

# إعداد السجلات
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# --- ضبط المسارات بذكاء ---
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
LIB_PATH = os.path.join(BASE_DIR, "lib")
BOT_PATH = os.path.join(LIB_PATH, "royal_door_bot")

if BASE_DIR not in sys.path: sys.path.insert(0, BASE_DIR)
if LIB_PATH not in sys.path: sys.path.insert(0, LIB_PATH)
if BOT_PATH not in sys.path: sys.path.insert(0, BOT_PATH)

from telegram import Update, BotCommand
from telegram.ext import ApplicationBuilder, CommandHandler, CallbackQueryHandler, MessageHandler, filters, ContextTypes

# --- الاستيراد من ملفات المشروع الأصلية ---
try:
    from lib.royal_door_bot.config import TOKEN as CONFIG_TOKEN
    from lib.royal_door_bot.core import STRINGS, get_main_keyboard
    from lib.royal_door_bot.db import db
    from lib.royal_door_bot.handlers.button_handler import handle_buttons
    from lib.royal_door_bot.handlers.start_handler import start
    from lib.royal_door_bot.handlers.message_handler import handle_message
    logger.info("✅ Full project logic loaded successfully")
except Exception as e:
    logger.error(f"❌ Error loading project logic: {e}")
    # قيم احتياطية
    TOKEN = os.getenv("BOT_TOKEN")
    async def start(u, c): await u.message.reply_text("Error loading bot logic.")
    async def handle_buttons(u, c): pass
    async def handle_message(u, c): pass

TOKEN = os.getenv("BOT_TOKEN") or (locals().get('CONFIG_TOKEN'))

def log_print(msg):
    print(f"[{datetime.now().strftime('%H:%M:%S')}] {msg}")
    sys.stdout.flush()

async def post_init(application):
    await application.bot.set_my_commands([BotCommand("start", "فتح القائمة الملكية 🏰")])

def main():
    if not TOKEN:
        print("❌ CRITICAL: TOKEN NOT FOUND")
        return
        
    application = ApplicationBuilder().token(TOKEN).post_init(post_init).build()
    
    application.add_handler(CommandHandler("start", start))
    application.add_handler(CallbackQueryHandler(handle_buttons))
    application.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND, handle_message))
    
    log_print("🚀 Royal Door Bot is FULLY CONNECTED and Live...")
    application.run_polling(drop_pending_updates=True)

if __name__ == "__main__":
    main()
