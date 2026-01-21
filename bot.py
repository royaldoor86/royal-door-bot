import os
import sys

# إضافة المجلد الحالي لمسار البحث
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

import logging
import random
import asyncio
try:
    import firebase_admin
    from firebase_admin import credentials, firestore
    from google.cloud.firestore_v1 import Increment, Query
except ImportError:
    firebase_admin = None
    credentials = None
    firestore = None
    Increment = None
    Query = None

from datetime import datetime, timedelta
from telegram import Update, InlineKeyboardButton, InlineKeyboardMarkup, WebAppInfo, BotCommand
from telegram.ext import (
    ApplicationBuilder, CommandHandler, CallbackQueryHandler, 
    MessageHandler, filters, ContextTypes
)

# استيراد من المجلد الفرعي lib بوضوح
try:
    from lib.royal_door_bot.badges import get_user_badge
    from lib.royal_door_bot.weekly_challenge import submit_weekly_answer
    from lib.royal_door_bot.media_utils import send_image, send_video
    from lib.royal_door_bot.support_tickets import create_ticket
    from lib.royal_door_bot.rewards_manager import set_reward
    from lib.royal_door_bot.core import STRINGS, get_main_keyboard
    from lib.royal_door_bot.db import db
except ImportError as e:
    print(f"Warning: Could not import some modules: {e}")
    # قيم افتراضية لتجنب الانهيار
    STRINGS = {'ar': {'welcome': "مرحباً {}", 'not_linked': "غير مرتبط", 'profile': "الملف", 'daily_wait': "انتظر", 'daily_ok': "تم"}}
    get_main_keyboard = lambda x: None
    db = None

# نظام الطباعة الفورية للمراقبة
def log_print(msg):
    print(f"[{datetime.now().strftime('%H:%M:%S')}] {msg}")
    sys.stdout.flush()

TOKEN = os.getenv("BOT_TOKEN")

if not TOKEN:
    try:
        from lib.royal_door_bot.config import TOKEN as CONFIG_TOKEN
        TOKEN = CONFIG_TOKEN
    except ImportError:
        raise ValueError("❌ BOT_TOKEN is not set")

async def start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if update.message and update.effective_user:
        await update.message.reply_text(
            STRINGS['ar']['welcome'].format(update.effective_user.first_name), 
            reply_markup=get_main_keyboard(True), 
            parse_mode="Markdown"
        )

async def post_init(application):
    await application.bot.set_my_commands([BotCommand("start", "القائمة الرئيسية")])

def main():
    if not TOKEN:
        return
    app = ApplicationBuilder().token(TOKEN).post_init(post_init).build()
    app.add_handler(CommandHandler("start", start))
    log_print("🚀 Bot is strictly running from ROOT...")
    app.run_polling()

if __name__ == "__main__":
    main()
