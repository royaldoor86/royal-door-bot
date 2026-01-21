import firebase_admin
from firebase_admin import credentials, firestore
import os
import json
import sys
from datetime import datetime

def log_print(msg):
    print(f"[{datetime.now().strftime('%H:%M:%S')}] {msg}")
    sys.stdout.flush()

# محاولة التهيئة
try:
    if not firebase_admin._apps:
        # 1. محاولة القراءة من متغير البيئة (للأمان في Railway)
        service_account_info = os.getenv("FIREBASE_SERVICE_ACCOUNT")
        
        if service_account_info:
            try:
                # تحويل النص إلى قاموس JSON
                cert_dict = json.loads(service_account_info)
                cred = credentials.Certificate(cert_dict)
                firebase_admin.initialize_app(cred)
                log_print("✅ Connected to Firebase via Environment Variable")
            except Exception as e:
                log_print(f"⚠️ Failed to init via Env Var: {e}")
                service_account_info = None

        # 2. إذا لم يتوفر متغير البيئة، نستخدم الملف التقليدي
        if not service_account_info:
            current_dir = os.path.dirname(os.path.abspath(__file__))
            json_path = os.path.join(current_dir, "serviceAccountKey.json")
            if os.path.exists(json_path):
                cred = credentials.Certificate(json_path)
                firebase_admin.initialize_app(cred)
                log_print("✅ Connected to Firebase via serviceAccountKey.json")
            else:
                log_print("❌ Firebase credentials NOT FOUND!")

    db = firestore.client()
except Exception as e:
    log_print(f"❌ Firebase Critical Error: {e}")
    db = None
