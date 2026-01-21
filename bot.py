import os
import sys
import logging
import asyncio
from datetime import datetime

# إعداد السجلات بشكل مكثف
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

from telegram import Update, BotCommand, InlineKeyboardButton, InlineKeyboardMarkup, WebAppInfo
from telegram.ext import ApplicationBuilder, CommandHandler, CallbackQueryHandler, MessageHandler, filters, ContextTypes

# --- الإعدادات ---
TOKEN = os.getenv("BOT_TOKEN") or "8351595801:AAF1UjhVKXzxoafS-nSVn2MPrpEc9pSQJ04"

# --- النصوص والأزرار ---
STRINGS = {
    'ar': {
        'welcome': "🏰 *أهلاً بك في رويال دور الملكي* 🏰\n\nأدر رصيدك واستلم هداياك من القائمة أدناه: 👇",
    }
}

def get_main_keyboard():
    keyboard = [
        [InlineKeyboardButton("🎁 هدية يومية", callback_data="daily"), InlineKeyboardButton("👤 رصيدي", callback_data="profile")],
        [InlineKeyboardButton("✨ مهام النقاط", callback_data="tasks")],
        [InlineKeyboardButton("🛒 المتجر الملكي", web_app=WebAppInfo(url="https://royaldoor.live/store"))],
        [InlineKeyboardButton("🎡 عجلة الحظ", callback_data="spin_wheel"), InlineKeyboardButton("🔄 تحويل", callback_data="convert")],
        [InlineKeyboardButton("👥 دعوة أصدقاء", callback_data="referral"), InlineKeyboardButton("🤝 الوكلاء", callback_data="agents")]
    ]
    return InlineKeyboardMarkup(keyboard)

# --- معالج الأوامر ---
async def start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    user = update.effective_user
    print(f"[{datetime.now()}] 👤 Received /start from: {user.first_name} ({user.id})")
    try:
        await update.message.reply_text(
            STRINGS['ar']['welcome'],
            reply_markup=get_main_keyboard(),
            parse_mode="Markdown"
        )
        print(f"✅ Response sent to {user.id}")
    except Exception as e:
        print(f"❌ Error sending message: {e}")

async def handle_callback(update: Update, context: ContextTypes.DEFAULT_TYPE):
    query = update.callback_query
    print(f"[{datetime.now()}] 🔘 Button pressed: {query.data} by {query.from_user.id}")
    await query.answer("جاري المعالجة...")
    
    # محاولة تمرير الطلب لمعالج الأزرار الأصلي إذا وجد
    try:
        from lib.royal_door_bot.handlers.button_handler import handle_buttons
        await handle_buttons(update, context)
    except Exception as e:
        print(f"⚠️ Could not use external button handler: {e}")
        await query.message.reply_text(f"تم الضغط على: {query.data} (قيد التطوير)")

async def post_init(application):
    await application.bot.set_my_commands([BotCommand("start", "فتح القائمة الملكية 🏰")])

def main():
    print("🚀 Attempting to start Royal Door Bot...")
    if not TOKEN:
        print("❌ CRITICAL: No TOKEN found!")
        return
        
    application = ApplicationBuilder().token(TOKEN).post_init(post_init).build()
    
    application.add_handler(CommandHandler("start", start))
    application.add_handler(CallbackQueryHandler(handle_callback))
    
    print("🚀 Master Bot is ONLINE and waiting for messages...")
    application.run_polling(drop_pending_updates=True)

if __name__ == "__main__":
    main()
