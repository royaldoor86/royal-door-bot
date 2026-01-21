# royaldoor_bot.py
# نقطة تشغيل رئيسية لتجميع جميع وظائف البوت في ملف واحد مستقل

import os
import sys
import logging
import random
import asyncio
from datetime import datetime, timedelta
from telegram import Update, InlineKeyboardButton, InlineKeyboardMarkup, WebAppInfo, ForceReply, BotCommand
from telegram.ext import (
    ApplicationBuilder, CommandHandler, CallbackQueryHandler, 
    MessageHandler, filters, ContextTypes
)

# استيراد الوظائف من ملفات البوت
from lib.royal_door_bot.badges import get_user_badge
from lib.royal_door_bot.weekly_challenge import submit_weekly_answer, WEEKLY_QUIZ
from lib.royal_door_bot.media_utils import send_image, send_video
from lib.royal_door_bot.support_tickets import create_ticket, get_user_tickets
from lib.royal_door_bot.rewards_manager import set_reward, get_reward
from lib.royal_door_bot.external_integration import send_email
from lib.royal_door_bot.handlers.start_handler import start
from lib.royal_door_bot.handlers.button_handler import handle_buttons
from lib.royal_door_bot.handlers.message_handler import handle_message

# روابط التواصل الاجتماعي
SOCIAL_LINKS = {
    "instagram": {"name": "انستغرام", "url": "https://instagram.com/royaldoor86"},
    "facebook": {"name": "فيسبوك", "url": "https://www.facebook.com/share/1ASAHLcLXy/"},
    "tiktok": {"name": "تيك توك", "url": "https://www.tiktok.com/@royaldoor86"}
}

def log_print(msg):
    print(f"[{datetime.now().strftime('%H:%M:%S')}] {msg}")
    sys.stdout.flush()

# إعداد التطبيق
async def main():
    # ضع هنا رمز التوكن الخاص بك
    TOKEN = os.getenv("BOT_TOKEN", "ضع_توكن_البوت_هنا")
    application = ApplicationBuilder().token(TOKEN).build()

    # إضافة الأوامر
    application.add_handler(CommandHandler("start", start))
    application.add_handler(CallbackQueryHandler(handle_buttons))
    application.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND, handle_message))

    log_print("البوت جاهز للعمل!")
    await application.run_polling()

if __name__ == "__main__":
    asyncio.run(main())
