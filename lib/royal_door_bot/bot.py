import os
import sys

# ضمان التعرف على مجلد lib كحزمة
current_dir = os.path.dirname(os.path.abspath(__file__))
project_root = os.path.abspath(os.path.join(current_dir, "../../"))
if project_root not in sys.path:
    sys.path.insert(0, project_root)

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
from telegram import Update, InlineKeyboardButton, InlineKeyboardMarkup, WebAppInfo, ForceReply, BotCommand
from telegram.ext import (
    ApplicationBuilder, CommandHandler, CallbackQueryHandler, 
    MessageHandler, filters, ContextTypes
)

# استيراد الميزات المتقدمة
try:
    from lib.royal_door_bot.badges import get_user_badge
    from lib.royal_door_bot.weekly_challenge import submit_weekly_answer, WEEKLY_QUIZ
    from lib.royal_door_bot.media_utils import send_image, send_video
    from lib.royal_door_bot.support_tickets import create_ticket, get_user_tickets
    from lib.royal_door_bot.rewards_manager import set_reward, get_reward
    from lib.royal_door_bot.external_integration import send_email
except ImportError:
    # في حال فشل الاستيراد رغم التعديلات
    get_user_badge = None
    submit_weekly_answer = None
    send_image = None
    send_video = None
    create_ticket = None
    set_reward = None
    send_email = None

# تعريف روابط التواصل الاجتماعي
SOCIAL_LINKS = {
    "instagram": {"name": "انستغرام", "url": "https://instagram.com/royaldoor86"},
    "facebook": {"name": "فيسبوك", "url": "https://www.facebook.com/share/1ASAHLcLXy/"},
    "tiktok": {"name": "تيك توك", "url": "https://www.tiktok.com/@royaldoor86"}
}

# نظام الطباعة الفورية للمراقبة
def log_print(msg):
    print(f"[{datetime.now().strftime('%H:%M:%S')}] {msg}")
    sys.stdout.flush()

# --- الإعدادات (تعديل الأمان للرفع على Railway) ---
TOKEN = os.getenv("BOT_TOKEN")

if not TOKEN:
    try:
        from lib.royal_door_bot.config import TOKEN as CONFIG_TOKEN
        TOKEN = CONFIG_TOKEN
    except ImportError:
        raise ValueError("❌ BOT_TOKEN is not set in environment variables or config.py")

json_path = os.path.join(current_dir, "serviceAccountKey.json")

# تهيئة قاعدة البيانات
try:
    from lib.royal_door_bot.db import db
except ImportError:
    if firebase_admin and not firebase_admin._apps:
        cred = credentials.Certificate(json_path)
        firebase_admin.initialize_app(cred)
        db = firestore.client()
    else:
        db = firestore.client()

try:
    from lib.royal_door_bot.core import STRINGS, get_main_keyboard
except ImportError:
    STRINGS = {'ar': {'welcome': "مرحباً {}", 'not_linked': "غير مرتبط", 'profile': "الملف الشخصي", 'daily_wait': "انتظر", 'daily_ok': "تم"}}
    get_main_keyboard = lambda x: None

async def start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    user_id = str(update.effective_user.id) if update.effective_user else None
    user_docs = db.collection('users').where('telegramId', '==', user_id).limit(1).get()
    if update.message and update.effective_user and hasattr(update.effective_user, "first_name"):
        await update.message.reply_text(STRINGS['ar']['welcome'].format(update.effective_user.first_name), reply_markup=get_main_keyboard(len(user_docs)>0), parse_mode="Markdown")

async def handle_buttons(update: Update, context: ContextTypes.DEFAULT_TYPE):
    query = update.callback_query
    if query is not None:
        await query.answer()
        user_id = str(query.from_user.id) if query.from_user else None
        user_name = query.from_user.first_name if query.from_user and hasattr(query.from_user, "first_name") else ""
    else:
        return
    
    user_docs = db.collection('users').where('telegramId', '==', user_id).limit(1).get()
    user_ref = user_docs[0].reference if user_docs else None
    user_data = user_docs[0].to_dict() if user_docs else None
    is_linked = user_ref is not None

    if query.data == "back_to_main":
        await query.message.edit_text(STRINGS['ar']['welcome'].format(user_name), reply_markup=get_main_keyboard(is_linked), parse_mode="Markdown")

    elif query.data == "profile":
        if not is_linked:
            await query.message.edit_text(STRINGS['ar']['not_linked'], reply_markup=get_main_keyboard(False))
            return
        text = STRINGS['ar']['profile'].format(
            user_data.get('name', ''),
            user_data.get('royalId', ''),
            user_data.get('botPoints', 0),
            user_data.get('gems', 0)
        )
        await query.message.edit_text(text, reply_markup=InlineKeyboardMarkup([[InlineKeyboardButton("🔙 عودة", callback_data="back_to_main")]]), parse_mode="Markdown")

    elif query.data == "daily":
        if not is_linked:
            await query.message.edit_text(STRINGS['ar']['not_linked'], reply_markup=get_main_keyboard(False))
            return
        last_claim = user_data.get('lastBotClaim')
        streak = user_data.get('botStreak', 0)
        now = datetime.now()
        if last_claim and (now - last_claim.replace(tzinfo=None)) < timedelta(days=1):
            await query.message.edit_text(STRINGS['ar']['daily_wait'], reply_markup=InlineKeyboardMarkup([[InlineKeyboardButton("🔙 عودة", callback_data="back_to_main")]]))
        else:
            streak = streak + 1 if last_claim and (now - last_claim.replace(tzinfo=None)) < timedelta(days=2) else 1
            reward = min(10 + (streak - 1) * 5, 50)
            user_ref.update({'botPoints': Increment(reward), 'lastBotClaim': now, 'botStreak': streak})
            await query.message.edit_text(STRINGS['ar']['daily_ok'].format(reward), reply_markup=InlineKeyboardMarkup([[InlineKeyboardButton("🔙 عودة", callback_data="back_to_main")]]))

async def post_init(application):
    await application.bot.set_my_commands([BotCommand("start", "فتح القائمة الرئيسية 🏰")])

def main():
    app = ApplicationBuilder().token(TOKEN).post_init(post_init).build()
    app.add_handler(CommandHandler("start", start))
    app.add_handler(CallbackQueryHandler(handle_buttons))
    log_print("🚀 Master Bot is Running...")
    app.run_polling()

if __name__ == "__main__":
    main()
