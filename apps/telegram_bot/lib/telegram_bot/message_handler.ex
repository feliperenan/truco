defmodule TelegramBot.MessageHandler do
  alias TelegramBot.TelegramMessage

  require Logger

  @type chat_response :: %{to: integer(), text: String.t()}

  @spec process_message(TelegramMessage.t()) :: chat_response()
  def process_message(%TelegramMessage{text: "/new", chat: %{type: "group"} = chat}) do
    game_name = "#{chat.title}-#{chat.id}"

    text =
      case Engine.new_game(game_name) do
        {:ok, _game_name} ->
          "The game has been created and it is ready for receive players."

        {:error, _error} ->
          ~s"""
          There is already a game created for this group.

          Try /join to join the game or /start to start the game.
          """
      end

    %{to: chat.id, text: text}
  end

  def process_message(%TelegramMessage{text: "/new", chat: %{id: chat_id, type: "private"}}) do
    text = ~s"""
    I can't start a game from a private conversation.

    In order to play the game, you need to create a group with people you want to play.
    """

    %{to: chat_id, text: text}
  end

  def process_message(%TelegramMessage{text: "/start", chat: %{type: "group"} = chat}),
    do: %{to: chat.id, text: "Feature has not been implemented yet..."}

  def process_message(%TelegramMessage{text: "/join", chat: %{type: "group"} = chat}),
    do: %{to: chat.id, text: "Feature has not been implemented yet..."}

  def process_message(%TelegramMessage{chat: chat} = message) do
    Logger.info(~s"""
    Could not process the given message:

    #{inspect(message)}
    """)

    %{to: chat.id, text: "Sorry, I didn't understand this message :(."}
  end
end
