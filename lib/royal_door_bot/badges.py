# نظام الشارات والمستويات للمستخدمين
BADGES = [
    {"name_ar": "مبتدئ", "name_en": "Beginner", "points": 0},
    {"name_ar": "نشط", "name_en": "Active", "points": 100},
    {"name_ar": "مميز", "name_en": "Special", "points": 500},
    {"name_ar": "VIP", "name_en": "VIP", "points": 1000},
    {"name_ar": "أسطورة", "name_en": "Legend", "points": 5000}
]

def get_user_badge(points, lang='ar'):
    for badge in reversed(BADGES):
        if points >= badge['points']:
            return badge['name_ar'] if lang == 'ar' else badge['name_en']
    return BADGES[0]['name_ar'] if lang == 'ar' else BADGES[0]['name_en']
