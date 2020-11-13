defmodule TelegramClient.Webhook do
  alias TelegramClient.Webhook.Message

  require Logger

  @doc """
  Handle message/command received from Telegram webhook.

  ### Possible commands

  - /new   - it will create a new game in the chat group.
  - /join  - it will join the sender to the created game.
  - /start - it will start a the game as long as it has enough players.
  """
  @spec handle_message(map()) :: :ok
  def handle_message(message_payload) do
    case Message.new(message_payload) do
      %Message{text: "/new@ex_truco_bot", chat: chat} ->
        # TODO:
        # * start a new game for this group and send this message to the bot.
        # * respond an error message in case it is not a chat group.
        Nadia.send_message(chat.id, "The game has been created and it is ready for receive players.")

        :ok

      %Message{text: "/join@ex_truco_bot", chat: chat} ->
        # join the message sender into the previously created game.
        Nadia.send_message(chat.id, "Feature has been not implemented yet...")

        :ok

      %Message{text: "/start@ex_truco_bot", chat: chat} ->
        # start the previously created game as long as it has enough players.
        Nadia.send_message(chat.id, "Feature has been not implemented yet...")

        :ok

      %Message{} = message ->
        Logger.info(~s"""
        Could not process the given message

        #{inspect(message)}
        """)

        :ok
    end
  end
end
