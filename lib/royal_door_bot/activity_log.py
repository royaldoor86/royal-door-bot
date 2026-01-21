# سجل النشاطات للمستخدم
from datetime import datetime
from firebase_admin import firestore

def log_user_activity(user_ref, activity_type, details=None):
    log_entry = {
        "type": activity_type,
        "details": details or {},
        "timestamp": datetime.now()
    }
    user_ref.update({
        "activityLog": firestore.ArrayUnion([log_entry])
    })

# مثال الاستخدام:
# log_user_activity(user_ref, "daily_reward", {"amount": 10})
# log_user_activity(user_ref, "task_completed", {"task_key": "fb"})
