# بنك تحديات وأسئلة أسبوعية متنوعة
from datetime import datetime
import random

CHALLENGES = [
    {
        "question_ar": "ما هو لون شعار رويال دور؟",
        "question_en": "What is the color of the Royal Door logo?",
        "answer": "ذهبي",
        "reward": 30
    },
    {
        "question_ar": "كم عدد غرف VIP في التطبيق؟",
        "question_en": "How many VIP rooms are in the app?",
        "answer": "4",
        "reward": 40
    },
    {
        "question_ar": "اذكر اسم أحد وكلاء رويال دور؟",
        "question_en": "Name one Royal Door agent?",
        "answer": "أي اسم صحيح",
        "reward": 25
    },
    {
        "question_ar": "ما هي العملة الافتراضية في التطبيق؟",
        "question_en": "What is the default currency in the app?",
        "answer": "كوينز",
        "reward": 20
    }
]

# اختيار تحدي عشوائي كل أسبوع

def get_weekly_challenge():
    week_num = datetime.now().isocalendar()[1]
    idx = week_num % len(CHALLENGES)
    return CHALLENGES[idx]
