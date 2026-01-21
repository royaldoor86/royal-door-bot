import os
import sys
import logging
import asyncio
from datetime import datetime

# إعداد السجلات
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# ضبط المسارات
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
LIB_PATH = os.path.join(BASE_DIR, "lib")
if BASE_DIR not in sys.path: sys.path.insert(0, BASE_DIR)
if LIB_PATH not in sys.path: sys.path.insert(0, LIB_PATH)

from telegram import Update, BotCommand, InlineKeyboardButton, InlineKeyboardMarkup, WebAppInfo
from telegram.ext import ApplicationBuilder, CommandHandler, CallbackQueryHandler, MessageHandler, filters, ContextTypes

# --- النصوص والأزرار ---
STRINGS = {
    'ar': {
        'welcome': "✨ *مرحباً بك في رويال دور - البوابة الملكية* ✨\n\nأهلاً بك يا *{}* في عالمك الملكي. 🏰",
    }
}

def get_main_keyboard(is_linked=True):
    keyboard = [
        [InlineKeyboardButton("🎁 هدية يومية", callback_data="daily"), InlineKeyboardButton("💰 رصيدي", callback_data="profile")],
        [InlineKeyboardButton("🛒 المتجر", web_app=WebAppInfo(url="https://royaldoor.live/store"))],
        [InlineKeyboardButton("🆘 الدعم", web_app=WebAppInfo(url="https://royaldoor.live/support"))]
    ]
    return InlineKeyboardMarkup(keyboard)

# --- استيراد المكونات ---
try:
    from lib.royal_door_bot.config import TOKEN as CONFIG_TOKEN
    from lib.royal_door_bot.db import db
    from lib.royal_door_bot.handlers.button_handler import handle_buttons
    from lib.royal_door_bot.handlers.message_handler import handle_message
except Exception as e:
    logger.error(f"❌ Error loading modules: {e}")
    db = None

TOKEN = os.getenv("BOT_TOKEN") or (locals().get('CONFIG_TOKEN'))

async def start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    user_name = update.effective_user.first_name
    await update.message.reply_text(
        STRINGS['ar']['welcome'].format(user_name),
        reply_markup=get_main_keyboard(),
        parse_mode="Markdown"
    )

async def post_init(application):
    # مسح الويب هوك والرسائل القديمة تماماً عند التشغيل
    await application.bot.delete_webhook(drop_pending_updates=True)
    await application.bot.set_my_commands([BotCommand("start", "فتح القائمة الملكية 🏰")])

def main():
    if not TOKEN:
        logger.error("❌ BOT_TOKEN is missing!")
        return
        
    application = ApplicationBuilder().token(TOKEN).post_init(post_init).build()
    
    application.add_handler(CommandHandler("start", start))
    application.add_handler(CallbackQueryHandler(handle_buttons))
    application.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND, handle_message))
    
    logger.info("🚀 Royal Door Bot is Live and resolving conflicts...")
    # استخدام drop_pending_updates لتنظيف الطابور عند البدء
    application.run_polling(drop_pending_updates=True)

if __name__ == "__main__":
    main()
