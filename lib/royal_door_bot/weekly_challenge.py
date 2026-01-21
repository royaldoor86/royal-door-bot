# نظام التحديات والمسابقات الأسبوعية

from datetime import datetime
from .db import db
from .weekly_challenges_bank import get_weekly_challenge

# اختيار تحدي الأسبوع الحالي
WEEKLY_QUIZ = get_weekly_challenge()

def submit_weekly_answer(user_id, answer):
    user_docs = db.collection('users').where('telegramId', '==', user_id).limit(1).get()
    if user_docs:
        user_ref = user_docs[0].reference
        user_ref.update({
            "weeklyQuiz": {
                "answer": answer,
                "timestamp": datetime.now()
            }
        })
        # منح مكافأة حسب بنك التحديات
        correct = (answer.strip() == WEEKLY_QUIZ['answer']) or (WEEKLY_QUIZ['answer'] == "أي اسم صحيح")
        if correct:
            user_ref.update({'botPoints': db.field_path('botPoints').increment(WEEKLY_QUIZ['reward'])})
            from .activity_log import log_user_activity
            log_user_activity(user_ref, "weekly_challenge", {"result": "correct", "reward": WEEKLY_QUIZ['reward']})
        else:
            from .activity_log import log_user_activity
            log_user_activity(user_ref, "weekly_challenge", {"result": "wrong"})
