# إدارة المكافآت ديناميكياً (لوحة تحكم خارجية)
from .db import db

def set_reward(key, value):
    db.collection('settings').document('rewards').set({key: value}, merge=True)

def get_reward(key, default=10):
    doc = db.collection('settings').document('rewards').get()
    data = doc.to_dict() if doc.exists else {}
    return data.get(key, default)

# يمكن ربط هذه الدوال بلوحة تحكم خارجية لتغيير المكافآت بسهولة
