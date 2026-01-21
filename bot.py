import os
import sys
import logging
import asyncio
from datetime import datetime

# إضافة المسارات
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from telegram import Update, BotCommand
from telegram.ext import ApplicationBuilder, CommandHandler, CallbackQueryHandler, MessageHandler, filters, ContextTypes

# استيراد الوظائف الكاملة
try:
    from lib.royal_door_bot.config import TOKEN as CONFIG_TOKEN
    from lib.royal_door_bot.core import STRINGS, get_main_keyboard
    from lib.royal_door_bot.db import db
    from lib.royal_door_bot.handlers.button_handler import handle_buttons
    from lib.royal_door_bot.handlers.start_handler import start
    from lib.royal_door_bot.handlers.message_handler import handle_message
except ImportError as e:
    print(f"CRITICAL IMPORT ERROR: {e}")
    # وظائف طوارئ بسيطة جداً
    async def start(u, c): await u.message.reply_text("Loading Royal Bot...")
    async def handle_buttons(u, c): pass
    async def handle_message(u, c): pass
    STRINGS = {'ar': {'welcome': "أهلاً بك 🏰"}}
    get_main_keyboard = lambda x: None

TOKEN = os.getenv("BOT_TOKEN") or CONFIG_TOKEN

def log_print(msg):
    print(f"[{datetime.now().strftime('%H:%M:%S')}] {msg}")
    sys.stdout.flush()

async def post_init(application):
    await application.bot.set_my_commands([BotCommand("start", "فتح القائمة الملكية 🏰")])

def main():
    if not TOKEN:
        print("❌ Error: BOT_TOKEN is missing")
        return
    
    # بناء التطبيق بأحدث إصدار PTB
    application = ApplicationBuilder().token(TOKEN).post_init(post_init).build()
    
    # إضافة المعالجات (Handlers)
    application.add_handler(CommandHandler("start", start))
    application.add_handler(CallbackQueryHandler(handle_buttons))
    application.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND, handle_message))
    
    log_print("🚀 Royal Door Bot is FULLY ONLINE...")
    application.run_polling()

if __name__ == "__main__":
    main()
