# تكامل مع خدمات خارجية (إيميل، تطبيقات)
import smtplib
from email.message import EmailMessage

def send_email(to, subject, body):
    msg = EmailMessage()
    msg['Subject'] = subject
    msg['From'] = 'noreply@royaldoor.live'
    msg['To'] = to
    msg.set_content(body)
    # إعدادات SMTP (مثال)
    with smtplib.SMTP('smtp.example.com', 587) as server:
        server.starttls()
        server.login('user', 'password')
        server.send_message(msg)

# يمكن إضافة تكامل مع تطبيقات أخرى عبر REST API أو Webhooks
