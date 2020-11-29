defmodule TelegramBot.MessageHandler do
  alias TelegramBot.TelegramMessage

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

  def process_message(%TelegramMessage{text: "/join", chat: %{type: "group"} = chat, from: from}) do
    game_name = "#{chat.title}-#{chat.id}"
    user_id = "#{from.id}-#{from.first_name}-#{from.last_name}"

    text =
      case Engine.join_player(game_name, user_id) do
        {:ok, _game} ->
          "You have joined the game. Now, wait for other players or send /start to start the game in case you have enough players."

        {:error, :game_not_found} ->
          "Game has not been created yet. First you need to send /new in order to create the game."

        {:error, :player_already_joined} ->
          "You have already joined the game. Now, wait for other players to join."

        {:error, :players_limit_reached} ->
          "This game cannot have more players. You are now ready to start the game with /start."
      end

    %{to: chat.id, text: text}
  end

  def process_message(%TelegramMessage{text: "/start", chat: %{type: "group"} = chat}),
    do: %{to: chat.id, text: "Feature has not been implemented yet..."}

  def process_message(%TelegramMessage{chat: chat}),
    do: %{to: chat.id, text: "Sorry, I didn't understand this message :(."}
end
