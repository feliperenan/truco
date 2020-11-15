import Config

config :telegram_client, port: 4000

config :nadia, token: System.get_env("TELEGRAM_BOT_API_KEY")
