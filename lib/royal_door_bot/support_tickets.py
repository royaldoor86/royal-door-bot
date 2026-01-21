# نظام تذاكر الدعم الفني
from datetime import datetime
from .db import db

def create_ticket(user_id, subject, message):
    ticket = {
        "user_id": user_id,
        "subject": subject,
        "message": message,
        "status": "open",
        "created_at": datetime.now()
    }
    db.collection('supportTickets').add(ticket)
    return ticket

def get_user_tickets(user_id):
    tickets = db.collection('supportTickets').where('user_id', '==', user_id).stream()
    return [t.to_dict() for t in tickets]

# يمكن إضافة زر في البوت لفتح تذكرة جديدة أو عرض التذاكر السابقة
