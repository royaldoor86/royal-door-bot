from telegram import Update, InlineKeyboardButton, InlineKeyboardMarkup, WebAppInfo, ForceReply
from telegram.ext import ContextTypes
from ..core import STRINGS, get_main_keyboard
from ..db import db
from ..tasks import TASKS
from datetime import datetime, timedelta
import random, asyncio

def get_user_lang(update: Update):
    lang = update.effective_user.language_code
    return lang if lang in STRINGS else 'ar'

async def handle_buttons(update: Update, context: ContextTypes.DEFAULT_TYPE):
    from ..tasks import TASKS
    try:
        query = update.callback_query
        await query.answer()
        user_id = str(query.from_user.id)
        user_name = query.from_user.first_name
        user_lang = get_user_lang(update)
        user_docs = db.collection('users').where('telegramId', '==', user_id).limit(1).get()
        user_ref = user_docs[0].reference if user_docs else None
        user_data = user_docs[0].to_dict() if user_docs else None
        is_linked = user_ref is not None

        # تسجيل نشاط إحالة عند منح النقاط بعد ربط الحساب
        if query.data.startswith("confirm_"):
            royal_id = query.data.split("_")[1]
            user_ref.update({'royalId': royal_id})
            referred_by = context.user_data.get('referred_by')
            if referred_by:
                ref_docs = db.collection('users').where('telegramId', '==', referred_by).limit(1).get()
                if ref_docs:
                    ref_user_ref = ref_docs[0].reference
                    ref_user_ref.update({'botPoints': db.field_path('botPoints').increment(50)})
                    from ..activity_log import log_user_activity
                    log_user_activity(ref_user_ref, "referral", {"ref_id": user_id})

        if query.data == "daily":
            if not is_linked:
                await query.answer(STRINGS[user_lang]['not_linked'], show_alert=True)
                return
            last_claim = user_data.get('lastBotClaim')
            streak = user_data.get('botStreak', 0)
            now = datetime.now()
            if last_claim and (now - last_claim.replace(tzinfo=None)) < timedelta(days=1):
                await query.message.edit_text(STRINGS[user_lang]['daily_wait'], reply_markup=InlineKeyboardMarkup([[InlineKeyboardButton("🔙 عودة", callback_data="back_to_main")]]))
            else:
                streak = streak + 1 if last_claim and (now - last_claim.replace(tzinfo=None)) < timedelta(days=2) else 1
                reward = min(10 + (streak - 1) * 5, 50)
                user_ref.update({'botPoints': db.field_path('botPoints').increment(reward), 'lastBotClaim': now, 'botStreak': streak})
                from ..activity_log import log_user_activity
                log_user_activity(user_ref, "daily_reward", {"amount": reward})
                await query.message.edit_text(STRINGS[user_lang]['daily_ok'].format(reward), reply_markup=InlineKeyboardMarkup([[InlineKeyboardButton("🔙 عودة", callback_data="back_to_main")]]))

        if query.data == "profile":
            if not is_linked:
                await query.message.edit_text(STRINGS[user_lang]['not_linked'], reply_markup=get_main_keyboard(False))
                return
            from ..badges import get_user_badge
            points = user_data.get('botPoints', 0)
            badge = get_user_badge(points, user_lang)
            text = STRINGS[user_lang]['profile'].format(user_data.get('name'), user_data.get('royalId'), points, user_data.get('gems', 0))
            text += f"\n🏅 شارتك الحالية: {badge}" if user_lang == 'ar' else f"\n🏅 Your badge: {badge}"
            # تخصيص رسالة VIP
            if badge == "VIP":
                text += "\n👑 أنت عضو VIP! استمتع بمزاياك الملكية." if user_lang == 'ar' else "\n👑 You are a VIP member! Enjoy your royal benefits."
            kb = InlineKeyboardMarkup([
                [InlineKeyboardButton("📜 سجل النشاطات", callback_data="activity_log")],
                [InlineKeyboardButton("📊 إحصائيات التحدي الأسبوعي", callback_data="weekly_stats")],
                [InlineKeyboardButton("🔙 عودة", callback_data="back_to_main")]
            ])
            await query.message.edit_text(text, reply_markup=kb, parse_mode="Markdown")

        if query.data == "weekly_stats":
            if not is_linked:
                await query.message.edit_text(STRINGS[user_lang]['not_linked'], reply_markup=get_main_keyboard(False))
                return
            stats = user_data.get('weeklyQuiz', {})
            answer = stats.get('answer', '-')
            ts = stats.get('timestamp', '-')
            txt = f"📊 إحصائيات التحدي الأسبوعي:\nآخر إجابة: {answer}\nالوقت: {ts}" if user_lang == 'ar' else f"📊 Weekly Challenge Stats:\nLast answer: {answer}\nTime: {ts}"
            await query.message.edit_text(txt, reply_markup=InlineKeyboardMarkup([[InlineKeyboardButton("🔙 عودة", callback_data="profile")]]))

        if query.data == "activity_log":
            if not is_linked:
                await query.message.edit_text(STRINGS[user_lang]['not_linked'], reply_markup=get_main_keyboard(False))
                return
            log = user_data.get('activityLog', [])
            if not log:
                txt = "لا يوجد نشاطات بعد." if user_lang == 'ar' else "No activities yet."
            else:
                txt = "📜 آخر نشاطاتك:\n\n" if user_lang == 'ar' else "📜 Your recent activities:\n\n"
                from ..tasks import TASKS
                for entry in log[-10:][::-1]:
                    t = entry.get('type')
                    ts = entry.get('timestamp')
                    details = entry.get('details', {})
                    if t == "task_completed":
                        task_key = details.get('task_key')
                        reward = details.get('reward')
                        task_obj = next((task for task in TASKS if task['key'] == task_key), None)
                        task_name = task_obj['title_ar'] if user_lang == 'ar' and task_obj else task_key
                        task_name_en = task_obj['title_en'] if user_lang == 'en' and task_obj else task_key
                        txt += f"✅ مهمة: {task_name} | نقاط: {reward} | {ts}\n" if user_lang == 'ar' else f"✅ Task: {task_name_en} | Points: {reward} | {ts}\n"
                    elif t == "daily_reward":
                        amount = details.get('amount')
                        txt += f"🎁 هدية يومية: +{amount} نقطة | {ts}\n" if user_lang == 'ar' else f"🎁 Daily gift: +{amount} points | {ts}\n"
                    elif t == "conversion":
                        to_type = details.get('to')
                        value = details.get('value')
                        txt += f"🔄 تحويل: {value} إلى {to_type} | {ts}\n" if user_lang == 'ar' else f"🔄 Conversion: {value} to {to_type} | {ts}\n"
                    elif t == "referral":
                        ref_id = details.get('ref_id')
                        txt += f"👥 إحالة صديق: {ref_id} | {ts}\n" if user_lang == 'ar' else f"👥 Friend referral: {ref_id} | {ts}\n"
                    else:
                        txt += f"🔸 {t} | {ts}\n"
            await query.message.edit_text(txt, reply_markup=InlineKeyboardMarkup([[InlineKeyboardButton("🔙 عودة", callback_data="profile")]]))

        if not is_linked:
            await query.message.edit_text(STRINGS[user_lang]['not_linked'], reply_markup=get_main_keyboard(False))
            return
        buttons = []
        user_tasks = user_data.get('completedTasks', {})
        for task in TASKS:
            if task['type'] == 'social':
                status = "✅" if user_tasks.get(task['key']) else "💎"
                title = task['title_ar'] if user_lang == 'ar' else task['title_en']
                buttons.append([InlineKeyboardButton(f"{status} {title}", url=task['url'])])
                if not user_tasks.get(task['key']):
                    buttons.append([InlineKeyboardButton(f"📥 تحقق واستلم {task['reward']} نقطة", callback_data=f"check_{task['key']}")])
            elif task['type'] == 'share':
                title = task['title_ar'] if user_lang == 'ar' else task['title_en']
                buttons.append([InlineKeyboardButton(f"🔗 {title}", callback_data=f"share_{task['key']}")])
        from ..weekly_challenge import WEEKLY_QUIZ
        buttons.append([InlineKeyboardButton("📝 تحدي الأسبوع", callback_data="weekly_challenge")])
        buttons.append([InlineKeyboardButton(STRINGS[user_lang]['back'], callback_data="back_to_main")])
        await query.message.edit_text(STRINGS[user_lang]['tasks_title'], reply_markup=InlineKeyboardMarkup(buttons), parse_mode="Markdown")

        # عرض سؤال التحدي الأسبوعي وإتاحة إرسال الإجابة
        if query.data == "weekly_challenge":
            from ..weekly_challenge import WEEKLY_QUIZ
            question = WEEKLY_QUIZ['question_ar'] if user_lang == 'ar' else WEEKLY_QUIZ['question_en']
            await query.message.reply_text(f"📝 تحدي الأسبوع:\n{question}\n\nأرسل إجابتك هنا.", reply_markup=ForceReply(selective=True))

        # تسجيل النشاط عند إكمال مهمة اجتماعية
        if query.data.startswith("check_"):
            task_key = query.data.split("_")[1]
            user_tasks = user_data.get('completedTasks', {})
            if not user_tasks.get(task_key):
                user_tasks[task_key] = True
                reward = next((t['reward'] for t in TASKS if t['key'] == task_key), 10)
                user_ref.update({'botPoints': db.field_path('botPoints').increment(reward), 'completedTasks': user_tasks})
                from ..activity_log import log_user_activity
                log_user_activity(user_ref, "task_completed", {"task_key": task_key, "reward": reward})
                await query.answer(f"🎉 تمت إضافة {reward} نقطة!", show_alert=True)
                await handle_buttons(update, context)
    except Exception as e:
        print(f"⚠️ خطأ غير متوقع: {e}")
        await update.callback_query.message.reply_text("⚠️ حدث خطأ غير متوقع. يرجى المحاولة لاحقاً.")
