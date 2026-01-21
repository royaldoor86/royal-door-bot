import os
import sys
import logging
import asyncio
from datetime import datetime

# إضافة المسارات
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from telegram import Update, BotCommand
from telegram.ext import ApplicationBuilder, CommandHandler, CallbackQueryHandler, MessageHandler, filters, ContextTypes

# محاولة الاستيراد مع معالجة التوكن
try:
    from lib.royal_door_bot.config import TOKEN as CONFIG_TOKEN
except ImportError:
    CONFIG_TOKEN = None

# استيراد المعالجات والوظائف
try:
    from lib.royal_door_bot.core import STRINGS, get_main_keyboard
    from lib.royal_door_bot.db import db
    from lib.royal_door_bot.handlers.button_handler import handle_buttons
    from lib.royal_door_bot.handlers.start_handler import start
    # إضافة معالج الرسائل العادية للإجابة على التحديات
    from lib.royal_door_bot.handlers.message_handler import handle_message
except ImportError as e:
    print(f"Warning: Handlers import failed: {e}")
    # وظائف بديلة لتجنب الانهيار التام
    async def start(u, c): await u.message.reply_text("Welcome!")
    async def handle_buttons(u, c): await u.callback_query.answer("Wait...")
    async def handle_message(u, c): pass
    STRINGS = {'ar': {'welcome': "مرحباً بك 🏰"}}
    get_main_keyboard = lambda x: None

TOKEN = os.getenv("BOT_TOKEN") or CONFIG_TOKEN

def log_print(msg):
    print(f"[{datetime.now().strftime('%H:%M:%S')}] {msg}")
    sys.stdout.flush()

async def post_init(application):
    await application.bot.set_my_commands([BotCommand("start", "القائمة الرئيسية 🏰")])

def main():
    if not TOKEN:
        print("❌ CRITICAL ERROR: BOT_TOKEN not found!")
        return
    
    application = ApplicationBuilder().token(TOKEN).post_init(post_init).build()
    
    # ربط الأوامر
    application.add_handler(CommandHandler("start", start))
    
    # ربط الأزرار (هذا ما كان ينقص البوت)
    application.add_handler(CallbackQueryHandler(handle_buttons))
    
    # ربط الرسائل (للتحديات الأسبوعية وغيرها)
    application.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND, handle_message))
    
    log_print("🚀 Master Bot is FULLY OPERATIONAL...")
    application.run_polling()

if __name__ == "__main__":
    main()
