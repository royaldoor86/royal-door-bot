from telegram import Update, InlineKeyboardButton, InlineKeyboardMarkup
from telegram.ext import ContextTypes
from ..db import db

def get_user_lang(update: Update):
    lang = update.effective_user.language_code
    return lang if lang in ['ar', 'en'] else 'ar'

async def handle_message(update: Update, context: ContextTypes.DEFAULT_TYPE):
    try:
        if update.message.reply_to_message:
            reply_text = update.message.reply_to_message.text
            # استقبال إجابة التحدي الأسبوعي
            if "تحدي الأسبوع" in reply_text or "Weekly Challenge" in reply_text:
                answer = update.message.text.strip()
                from ..weekly_challenge import submit_weekly_answer, WEEKLY_QUIZ
                user_id = str(update.effective_user.id)
                user_docs = db.collection('users').where('telegramId', '==', user_id).limit(1).get()
                user_ref = user_docs[0].reference if user_docs else None
                submit_weekly_answer(user_id, answer)
                # تحقق من صحة الإجابة
                correct = (answer.strip() == WEEKLY_QUIZ['answer']) or (WEEKLY_QUIZ['answer'] == "أي اسم صحيح")
                if correct:
                    msg = f"🎉 إجابة صحيحة! حصلت على {WEEKLY_QUIZ['reward']} نقطة."
                else:
                    msg = "❌ إجابة غير صحيحة. حاول مرة أخرى الأسبوع القادم!"
                # عرض إحصائيات التحديات
                stats = user_ref.get().to_dict().get('weeklyQuiz', {}) if user_ref else {}
                stats_txt = f"\n\n📊 إحصائياتك:\nآخر إجابة: {stats.get('answer', '-')}, الوقت: {stats.get('timestamp', '-')}"
                await update.message.reply_text(msg + stats_txt, reply_markup=InlineKeyboardMarkup([[InlineKeyboardButton("🔙 عودة", callback_data="back_to_main")]]))
            # استقبال ربط الآيدي الملكي
            elif "الآيدي" in reply_text:
                royal_id = update.message.text.strip()
                user_query = db.collection('users').where('royalId', '==', royal_id).limit(1).get()
                if user_query:
                    data = user_query[0].to_dict()
                    kb = InlineKeyboardMarkup([
                        [InlineKeyboardButton("✅ موافق وتفعيل", callback_data=f"confirm_{royal_id}")],
                        [InlineKeyboardButton("❌ إلغاء", callback_data="back_to_main")]
                    ])
                    await update.message.reply_text(
                        f"👑 تم العثور على: *{data.get('name')}*\nهل تريد الربط؟",
                        reply_markup=kb,
                        parse_mode="Markdown"
                    )
                else:
                    await update.message.reply_text("❌ الآيدي غير موجود.")
    except Exception as e:
        print(f"⚠️ خطأ غير متوقع: {e}")
        await update.message.reply_text("⚠️ حدث خطأ غير متوقع. يرجى المحاولة لاحقاً.")
