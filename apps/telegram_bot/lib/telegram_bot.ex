defmodule TelegramBot do
  alias TelegramBot.TelegramMessage
  alias TelegramBot.MessageHandler

  @doc """
  Process the given command received from Telegram webhook.

  ### Possible commands

  - /new   - it will create a new game in the chat group.
  - /join  - it will join the sender to the created game.
  - /start - it will start a the game as long as it has enough players.
  """
  @spec process_message(map()) :: :ok
  def process_message(message_payload) do
    %{to: chat_id, text: text} =
      message_payload
      |> TelegramMessage.new()
      |> MessageHandler.process_message()

    {:ok, _message} = Nadia.send_message(chat_id, text)

    :ok
  end
end
