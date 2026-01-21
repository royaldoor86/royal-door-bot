from telegram import Update
from telegram.ext import ApplicationBuilder, CommandHandler, ContextTypes

TOKEN = "7777931961:AAEGaJmRXscPL_gdcRerg3nI0pxGug-LwQ0"

async def start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if update.message is not None:
        await update.message.reply_text(
            "👑 مرحبًا بك في Royal Door\n\nالبوت يعمل بنجاح ✅"
        )

def main():
    app = ApplicationBuilder().token(TOKEN).build()
    app.add_handler(CommandHandler("start", start))
    print("🤖 Bot is running...")
    import asyncio
    asyncio.run(app.bot.delete_webhook())
    app.run_polling()

if __name__ == "__main__":
    main()