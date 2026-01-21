import os
import sys
import logging
import asyncio
from datetime import datetime

# إعداد السجلات
logging.basicConfig(format='%(asctime)s - %(name)s - %(levelname)s - %(message)s', level=logging.INFO)

# إضافة المجلد الحالي للمسار
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from telegram import Update, BotCommand
from telegram.ext import ApplicationBuilder, CommandHandler, ContextTypes

# محاولة الاستيراد من المجلد الفرعي
try:
    from lib.royal_door_bot.core import STRINGS, get_main_keyboard
    from lib.royal_door_bot.db import db
except ImportError as e:
    print(f"Warning: Module import failed: {e}")
    STRINGS = {'ar': {'welcome': "مرحباً بك في بوت رويال دور 🏰"}}
    get_main_keyboard = lambda x: None
    db = None

# نظام الطباعة الفورية
def log_print(msg):
    print(f"[{datetime.now().strftime('%H:%M:%S')}] {msg}")
    sys.stdout.flush()

TOKEN = os.getenv("BOT_TOKEN")

async def start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if update.effective_user:
        welcome_msg = STRINGS['ar']['welcome'].format(update.effective_user.first_name)
        await update.message.reply_text(welcome_msg)

async def post_init(application):
    await application.bot.set_my_commands([BotCommand("start", "تشغيل البوت")])

def main():
    if not TOKEN:
        print("❌ Error: BOT_TOKEN not found in environment variables")
        return
    
    # بناء التطبيق بطريقة متوافقة مع PTB 21.x
    application = ApplicationBuilder().token(TOKEN).post_init(post_init).build()
    
    application.add_handler(CommandHandler("start", start))
    
    log_print("🚀 Master Bot is Running (PTB 21.10) ...")
    application.run_polling()

if __name__ == "__main__":
    main()
