from telegram import Update, InlineKeyboardButton, InlineKeyboardMarkup
from telegram.ext import ContextTypes
from ..core import STRINGS, get_main_keyboard
from ..db import db
from ..tasks import TASKS
from datetime import datetime, timedelta
from google.cloud.firestore_v1.base_query import FieldFilter
import random

def get_user_lang(update: Update):
    lang = update.effective_user.language_code
    return lang if lang in STRINGS else 'ar'

async def handle_buttons(update: Update, context: ContextTypes.DEFAULT_TYPE):
    try:
        query = update.callback_query
        if not query: return
        await query.answer()
        
        user_id = str(query.from_user.id)
        user_name = query.from_user.first_name
        user_lang = get_user_lang(update)
        
        # جلب بيانات المستخدم
        user_docs = db.collection('users').where(filter=FieldFilter('telegramId', '==', user_id)).limit(1).get()
        user_ref = user_docs[0].reference if user_docs else None
        user_data = user_docs[0].to_dict() if user_docs else None
        is_linked = user_ref is not None

        # 1. العودة للقائمة الرئيسية
        if query.data == "back_to_main":
            await query.message.edit_text(
                STRINGS[user_lang]['welcome'].format(user_name), 
                reply_markup=get_main_keyboard(is_linked), 
                parse_mode="Markdown"
            )

        # 2. الملف الشخصي
        elif query.data == "profile":
            if not is_linked:
                await query.message.edit_text(STRINGS[user_lang]['not_linked'], reply_markup=get_main_keyboard(False))
                return
            
            points = user_data.get('botPoints', 0)
            text = STRINGS[user_lang]['profile'].format(
                user_data.get('name', 'Unknown'), 
                user_data.get('royalId', 'N/A'), 
                points, 
                user_data.get('gems', 0)
            )
            
            kb = InlineKeyboardMarkup([
                [InlineKeyboardButton("📜 سجل النشاطات", callback_data="activity_log")],
                [InlineKeyboardButton("🔙 عودة", callback_data="back_to_main")]
            ])
            await query.message.edit_text(text, reply_markup=kb, parse_mode="Markdown")

        # 3. الهدية اليومية
        elif query.data == "daily":
            if not is_linked:
                await query.answer(STRINGS[user_lang]['not_linked'], show_alert=True)
                return
            
            last_claim = user_data.get('lastBotClaim')
            now = datetime.now()
            
            if last_claim and (now - last_claim.replace(tzinfo=None)) < timedelta(days=1):
                await query.message.edit_text(STRINGS[user_lang]['daily_wait'], reply_markup=InlineKeyboardMarkup([[InlineKeyboardButton("🔙 عودة", callback_data="back_to_main")]]))
            else:
                reward = 20
                user_ref.update({'botPoints': db.field_path('botPoints').increment(reward), 'lastBotClaim': now})
                await query.message.edit_text(STRINGS[user_lang]['daily_ok'].format(reward), reply_markup=InlineKeyboardMarkup([[InlineKeyboardButton("🔙 عودة", callback_data="back_to_main")]]))

        # 4. المهام (Tasks)
        elif query.data == "tasks":
            if not is_linked:
                await query.message.edit_text(STRINGS[user_lang]['not_linked'], reply_markup=get_main_keyboard(False))
                return
            
            buttons = []
            user_tasks = user_data.get('completedTasks', {})
            for task in TASKS:
                status = "✅" if user_tasks.get(task['key']) else "💎"
                title = task['title_ar'] if user_lang == 'ar' else task['title_en']
                buttons.append([InlineKeyboardButton(f"{status} {title}", url=task.get('url', '#'))])
            
            buttons.append([InlineKeyboardButton("🔙 عودة", callback_data="back_to_main")])
            await query.message.edit_text("📋 المهام المتاحة:", reply_markup=InlineKeyboardMarkup(buttons))

    except Exception as e:
        print(f"⚠️ Error in button_handler: {e}")
        try:
            await query.message.reply_text("⚠️ حدث خطأ أثناء معالجة الزر.")
        except: pass
