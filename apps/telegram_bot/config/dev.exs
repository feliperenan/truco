import Config

config :telegram_bot, port: 4000

telegram_bot_api_key =
  System.get_env("TELEGRAM_BOT_API_KEY") ||
    raise """
    environment variable TELEGRAM_BOT_API_KEY is missing.
    """

config :nadia, token: System.get_env("TELEGRAM_BOT_API_KEY")
