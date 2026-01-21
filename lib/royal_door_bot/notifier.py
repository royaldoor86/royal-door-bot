# نظام الإشعارات التلقائية اليومية لجميع المستخدمين
import asyncio
from telegram import Bot
from .bot import TOKEN, STRINGS, db
from datetime import datetime

async def send_daily_notifications():
    bot = Bot(token=TOKEN)
    users = db.collection('users').stream()
    for user_doc in users:
        user = user_doc.to_dict()
        tg_id = user.get('telegramId')
        lang = user.get('lang', 'ar')
        msg = STRINGS[lang]['welcome'] if lang in STRINGS else STRINGS['ar']['welcome']
        try:
            await bot.send_message(chat_id=tg_id, text=f"🌟 إشعار يومي: لا تنسَ الحصول على هديتك الملكية اليوم!\n\n{msg.format(user.get('name', 'صديق'))}", parse_mode="Markdown")
        except Exception as e:
            print(f"خطأ إرسال إشعار للمستخدم {tg_id}: {e}")

# لتشغيل الإشعارات يومياً يمكن استخدام جدولة خارجية (مثل cron أو APScheduler)
# مثال: asyncio.run(send_daily_notifications())
