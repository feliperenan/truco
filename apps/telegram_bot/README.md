# TelegramBot

This is a telegram bot which provides a way of playing the truco game using inline queries. 

The game logic is inside `../engine`, so that this bot is the client that receives user requests from a Telegram chat
once this bot is installed in there.

## Setup

* Create a telegram bot: https://core.telegram.org/bots
* Once your bot is created, you need to get your bot `API_KEY` and set on this app: `export TELEGRAM_BOT_API_KEY="your-bot-key"`
* Also, set inline mode with `/setinline` and `setinlinefeedback`. Both commands is meant to be executed with your `BotFather`
* Upload images using `../image_uploader` project.
* mix deps.get
* iex -S mix

## Getting messages from Telegram

This bot get messages from telegram using webhooks: https://core.telegram.org/bots/api#setwebhook. So you need to setup your endpoint there, which can be done by this request:

```
curl https://api.telegram.org/your-bot-key/setWebhook\?url\=your-url/telegram/some-key
```

So that:

* `your-bot-key` is the same key you have set one step before when you've created your bot.
* `your-url` is a valid domain that will receive telegram requests. For developing, I use ngrok for generating public URL.
* `some-key` is some special key that only Telegram knows which can be used to verify if incoming requests are from Telegram. You can use `your-bot-key` since only Telegram should know that.

## Getting telegram messages on localhost

* Download ngrok: https://ngrok.com/download
* Start ngrok up pointing to your localhost: `./ngrok http localhost:4000`
* You should see that ngrok is forwarding a public https URL to your localhost. Copy this URL and set this on telegram as the webbook url.

## Running tests

* mix test