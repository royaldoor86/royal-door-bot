import os
import sys
import logging
import asyncio
from datetime import datetime

# إضافة المسارات
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from telegram import Update, BotCommand
from telegram.ext import ApplicationBuilder, CommandHandler, ContextTypes

# محاولة الاستيراد مع معالجة التوكن
try:
    from lib.royal_door_bot.config import TOKEN as CONFIG_TOKEN
except ImportError:
    CONFIG_TOKEN = None

try:
    from lib.royal_door_bot.core import STRINGS, get_main_keyboard
    from lib.royal_door_bot.db import db
except ImportError as e:
    STRINGS = {'ar': {'welcome': "مرحباً بك في بوت رويال دور 🏰"}}
    get_main_keyboard = lambda x: None
    db = None

TOKEN = os.getenv("BOT_TOKEN") or CONFIG_TOKEN

def log_print(msg):
    print(f"[{datetime.now().strftime('%H:%M:%S')}] {msg}")
    sys.stdout.flush()

async def start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if update.effective_user:
        welcome_text = STRINGS['ar']['welcome'].format(update.effective_user.first_name)
        await update.message.reply_text(welcome_text, reply_markup=get_main_keyboard(True))

async def post_init(application):
    await application.bot.set_my_commands([BotCommand("start", "تشغيل القائمة")])

def main():
    if not TOKEN:
        print("❌ CRITICAL ERROR: BOT_TOKEN not found!")
        return
    
    application = ApplicationBuilder().token(TOKEN).post_init(post_init).build()
    application.add_handler(CommandHandler("start", start))
    
    log_print("🚀 Master Bot is ONLINE and ready...")
    application.run_polling()

if __name__ == "__main__":
    main()
