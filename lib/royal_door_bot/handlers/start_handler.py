from telegram import Update
from telegram.ext import ContextTypes
from ..core import STRINGS, get_main_keyboard
from ..db import db
from google.cloud.firestore_v1.base_query import FieldFilter

def get_user_lang(update: Update):
    lang = update.effective_user.language_code
    return lang if lang in STRINGS else 'ar'

async def start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    try:
        user_id = str(update.effective_user.id)
        user_lang = get_user_lang(update)
        
        if context.args and context.args[0].startswith('ref_'):
            context.user_data['referred_by'] = context.args[0].replace('ref_', '')
        
        # استخدام الطريقة الجديدة للفلاتر لتجنب التحذيرات
        user_docs = db.collection('users').where(filter=FieldFilter('telegramId', '==', user_id)).limit(1).get()
        
        is_linked = len(user_docs) > 0
        
        await update.message.reply_text(
            STRINGS[user_lang]['welcome'].format(update.effective_user.first_name),
            reply_markup=get_main_keyboard(is_linked),
            parse_mode="Markdown"
        )
    except Exception as e:
        print(f"⚠️ Error in start_handler: {e}")
        await update.message.reply_text("⚠️ حدث خطأ غير متوقع. يرجى المحاولة لاحقاً.")
