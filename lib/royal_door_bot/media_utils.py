# دعم إرسال الصور والفيديوهات عبر البوت
from telegram import Bot
from .config import TOKEN

from telegram.ext import Application

async def send_image(chat_id, image_path, caption=None):
    application = Application.builder().token(TOKEN).build()
    with open(image_path, 'rb') as image_file:
        await application.bot.send_photo(chat_id=chat_id, photo=image_file, caption=caption)

async def send_video(chat_id, video_path, caption=None):
    application = Application.builder().token(TOKEN).build()
    with open(video_path, 'rb') as video_file:
        await application.bot.send_video(chat_id=chat_id, video=video_file, caption=caption)

# يمكن استدعاء هذه الدوال من أي مكان في النظام لإرسال وسائط للمستخدمين
