import Config
import Logger

config :telegram_bot, port: 4000

if System.get_env("TELEGRAM_BOT_API_KEY") |> is_nil() do
  Logger.warn("environment variable TELEGRAM_BOT_API_KEY is missing.")
end

config :nadia, token: System.get_env("TELEGRAM_BOT_API_KEY")
