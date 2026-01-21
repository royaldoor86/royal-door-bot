import os
import sys
import logging
import asyncio
from datetime import datetime

# إعداد السجلات لرؤية الأخطاء في Railway
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# إضافة المسارات
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from telegram import Update, BotCommand, InlineKeyboardButton, InlineKeyboardMarkup, WebAppInfo
from telegram.ext import ApplicationBuilder, CommandHandler, CallbackQueryHandler, MessageHandler, filters, ContextTypes

# --- النصوص والأزرار مدمجة لضمان الظهور ---
STRINGS = {
    'ar': {
        'welcome': "🏰 *أهلاً بك في رويال دور - النسخة الملكية* 🏰\n\nأدر رصيدك واستلم هداياك من القائمة أدناه: 👇",
    }
}

def get_main_keyboard(is_linked=True):
    keyboard = [
        [InlineKeyboardButton("🎁 هدية يومية", callback_data="daily"), InlineKeyboardButton("👤 رصيدي", callback_data="profile")],
        [InlineKeyboardButton("✨ مهام النقاط", callback_data="tasks")],
        [InlineKeyboardButton("🛒 المتجر الملكي", web_app=WebAppInfo(url="https://royaldoor.live/store"))],
        [InlineKeyboardButton("🎡 عجلة الحظ", callback_data="spin_wheel"), InlineKeyboardButton("🔄 تحويل", callback_data="convert")],
        [InlineKeyboardButton("👥 دعوة أصدقاء", callback_data="referral"), InlineKeyboardButton("🆘 الدعم", web_app=WebAppInfo(url="https://royaldoor.live/support"))]
    ]
    return InlineKeyboardMarkup(keyboard)

# --- محاولة ربط المعالجات الخارجية ---
try:
    from lib.royal_door_bot.config import TOKEN as CONFIG_TOKEN
    from lib.royal_door_bot.handlers.button_handler import handle_buttons
    from lib.royal_door_bot.handlers.start_handler import start as original_start
    from lib.royal_door_bot.handlers.message_handler import handle_message
    logger.info("✅ All modules imported successfully")
except Exception as e:
    logger.error(f"⚠️ Module import error: {e}")
    # معالجات طوارئ في حال فشل الاستيراد
    async def handle_buttons(u, c): await u.callback_query.answer("جاري التحديث...")
    async def handle_message(u, c): pass
    original_start = None

TOKEN = os.getenv("BOT_TOKEN") or "8351595801:AAF1UjhVKXzxoafS-nSVn2MPrpEc9pSQJ04"

async def start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not update.effective_user: return
    
    # إذا نجح الاستيراد نستخدم المعالج الأصلي، وإلا نستخدم المعالج المضمون هنا
    if original_start:
        await original_start(update, context)
    else:
        welcome_text = STRINGS['ar']['welcome']
        await update.message.reply_text(welcome_text, reply_markup=get_main_keyboard(), parse_mode="Markdown")

async def post_init(application):
    await application.bot.set_my_commands([BotCommand("start", "فتح القائمة الملكية 🏰")])

def main():
    if not TOKEN:
        print("❌ BOT_TOKEN is missing")
        return
    
    application = ApplicationBuilder().token(TOKEN).post_init(post_init).build()
    
    application.add_handler(CommandHandler("start", start))
    application.add_handler(CallbackQueryHandler(handle_buttons))
    application.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND, handle_message))
    
    print("🚀 Royal Door Bot is starting with Guaranteed UI...")
    application.run_polling()

if __name__ == "__main__":
    main()
