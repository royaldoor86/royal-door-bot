from telegram import Update
from telegram.ext import ApplicationBuilder, CommandHandler, ContextTypes

TOKEN = "8351595801:AAHeGbikNatcTxfyWwuEpR-UqO61HTmHvCg"

async def start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if update.message is not None:
        await update.message.reply_text(
            "👑 مرحبًا بك في Royal Door\n\nالبوت يعمل بنجاح ✅"
        )

def main():
    app = ApplicationBuilder().token(TOKEN).build()
    app.add_handler(CommandHandler("start", start))
    print("🤖 Bot is running...")
    app.run_polling()

if __name__ == "__main__":
    main()