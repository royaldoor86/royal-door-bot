import os
import sys
import logging
import asyncio
from datetime import datetime

# إعداد السجلات
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# ضبط المسارات لضمان التعرف على المجلدات في Railway
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
LIB_PATH = os.path.join(BASE_DIR, "lib")
if BASE_DIR not in sys.path: sys.path.insert(0, BASE_DIR)
if LIB_PATH not in sys.path: sys.path.insert(0, LIB_PATH)

from telegram import Update, BotCommand, InlineKeyboardButton, InlineKeyboardMarkup, WebAppInfo
from telegram.ext import ApplicationBuilder, CommandHandler, CallbackQueryHandler, MessageHandler, filters, ContextTypes

# --- نصوص الأزرار (مدمجة لضمان الظهور الفوري) ---
STRINGS = {
    'ar': {
        'welcome': (
            "✨ *مرحباً بك في رويال دور - البوابة الملكية* ✨\n\n"
            "أهلاً بك يا *{}* في عالمك الملكي. 🏰\n\n"
            "🌟 *استخدم القائمة أدناه للوصول لميزاتك:* 👇"
        ),
        'db_error': "⚠️ عذراً، نواجه مشكلة حالياً في الاتصال بقاعدة البيانات. يرجى المحاولة لاحقاً."
    }
}

def get_main_keyboard(is_linked=True):
    keyboard = [
        [InlineKeyboardButton("🎁 هدية يومية", callback_data="daily"), InlineKeyboardButton("💰 رصيدي", callback_data="profile")],
        [InlineKeyboardButton("✨ اربح نقاط مجانية", callback_data="tasks")],
        [InlineKeyboardButton("🛒 المتجر", web_app=WebAppInfo(url="https://royaldoor.live/store")), InlineKeyboardButton("🎡 عجلة الحظ", callback_data="spin_wheel")],
        [InlineKeyboardButton("🔄 تحويل النقاط", callback_data="convert"), InlineKeyboardButton("🏆 المتصدرين", callback_data="leaderboard")],
        [InlineKeyboardButton("👥 دعوة أصدقاء", callback_data="referral")],
        [InlineKeyboardButton("👑 حالة VIP", callback_data="vip"), InlineKeyboardButton("🤝 وكلاء رويال دور", callback_data="agents_list")],
        [InlineKeyboardButton("🆘 الدعم", web_app=WebAppInfo(url="https://royaldoor.live/support"))]
    ]
    return InlineKeyboardMarkup(keyboard)

# --- استيراد المنطق بشكل آمن (واحد بواحد) ---
try:
    from lib.royal_door_bot.config import TOKEN as CONFIG_TOKEN
except: CONFIG_TOKEN = None

try:
    from lib.royal_door_bot.db import db
except Exception as e:
    logger.error(f"❌ Firebase Error: {e}")
    db = None

try:
    from lib.royal_door_bot.handlers.button_handler import handle_buttons
except:
    async def handle_buttons(u, c): await u.callback_query.answer("⚠️ الوظيفة قيد الإصلاح...")

try:
    from lib.royal_door_bot.handlers.message_handler import handle_message
except:
    async def handle_message(u, c): pass

TOKEN = os.getenv("BOT_TOKEN") or CONFIG_TOKEN

async def start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not update.effective_user: return
    user_name = update.effective_user.first_name
    
    is_linked = False
    if db:
        try:
            user_id = str(update.effective_user.id)
            user_docs = db.collection('users').where('telegramId', '==', user_id).limit(1).get()
            is_linked = len(user_docs) > 0
        except: pass

    await update.message.reply_text(
        STRINGS['ar']['welcome'].format(user_name),
        reply_markup=get_main_keyboard(is_linked),
        parse_mode="Markdown"
    )

async def post_init(application):
    await application.bot.delete_webhook(drop_pending_updates=True)
    await application.bot.set_my_commands([BotCommand("start", "القائمة الملكية 🏰")])

def main():
    if not TOKEN:
        logger.error("❌ BOT_TOKEN is missing!")
        return
        
    application = ApplicationBuilder().token(TOKEN).post_init(post_init).build()
    
    application.add_handler(CommandHandler("start", start))
    application.add_handler(CallbackQueryHandler(handle_buttons))
    application.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND, handle_message))
    
    logger.info("🚀 Royal Door Bot is Live and Fixed...")
    application.run_polling(drop_pending_updates=True)

if __name__ == "__main__":
    main()
