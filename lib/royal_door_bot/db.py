import firebase_admin
from firebase_admin import credentials, firestore
import os
import sys
from datetime import datetime

def log_print(msg):
    print(f"[{datetime.now().strftime('%H:%M:%S')}] {msg}")
    sys.stdout.flush()

current_dir = os.path.dirname(os.path.abspath(__file__))
json_path = os.path.join(current_dir, "serviceAccountKey.json")

try:
    if not firebase_admin._apps:
        cred = credentials.Certificate(json_path)
        firebase_admin.initialize_app(cred)
    db = firestore.client()
    log_print("✅ متصل بـ Firebase (db.py)")
except Exception as e:
    log_print(f"⚠️ خطأ Firebase: {e}")
