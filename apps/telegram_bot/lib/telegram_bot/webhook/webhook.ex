defmodule TelegramBot.Webhook do
  alias TelegramBot.Webhook.Message

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
      %Message{text: "/new", chat: chat} ->
        new_game(chat)

      %Message{text: "/join@ex_truco_bot", chat: chat} ->
        # join the message sender into the previously created game.
        Nadia.send_message(chat.id, "Feature has not been implemented yet...")

        :ok

      %Message{text: "/start@ex_truco_bot", chat: chat} ->
        # start the previously created game as long as it has enough players.
        Nadia.send_message(chat.id, "Feature has not been implemented yet...")

        :ok

      %Message{} = message ->
        Logger.info(~s"""
        Could not process the given message

        #{inspect(message)}
        """)

        :ok
    end
  end

  defp new_game(%{type: "private"} = chat) do
    message = ~s"""
    I can't start a game from a private conversation.

    In order to play the game, you need to create a group with people you want to play."
    """

    Nadia.send_message(chat.id, message)

    :ok
  end

  defp new_game(%{type: "group"} = chat) do
    game_name = "#{chat.title}-#{chat.id}"

    case Engine.new_game(game_name) do
      {:ok, _game_name} ->
        Nadia.send_message(chat.id, "The game has been created and it is ready for receive players.")

      {:error, _error} ->
        Nadia.send_message(
          chat.id,
          "There is already a game created for this group. Try /join to join the game or /start to start the game."
        )
    end

    :ok
  end
end
