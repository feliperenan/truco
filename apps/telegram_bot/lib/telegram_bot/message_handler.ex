defmodule TelegramBot.MessageHandler do
  alias TelegramBot.TelegramMessage

  @type chat_response :: %{to: integer(), text: String.t()} | list(map())

  @emoji_unicode_map %{
    spades: "♠️",
    hearts: "❤️",
    diamonds: "♦️",
    clubs: "♣️"
  }

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

    text =
      case Engine.join_player(game_name, from.username) do
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

  def process_message(%TelegramMessage{text: "/start", chat: %{type: "group"} = chat}) do
    game_name = "#{chat.title}-#{chat.id}"

    case Engine.start_game(game_name) do
      {:ok, %Engine.Game{} = game} ->
        current_match = List.last(game.matches)
        player_turn = Enum.find(game.players, &(&1.id == current_match.next_player_id))
        suit_emoji = @emoji_unicode_map[current_match.card_faced_up.suit]

        text = ~s"""
        The game has been started

        The card faced up is: #{current_match.card_faced_up.symbol} #{suit_emoji}
        The player who starts is: @#{player_turn.name}

        To check your cards, send /my_cards
        """

        %{to: chat.id, text: text}

      {:error, :game_already_started} ->
        %{to: chat.id, text: "Game has been started already"}

      {:error, _error_message} ->
        %{to: chat.id, text: "There is something wrong so I couldn't start the game :("}
    end
  end

  def process_message(%TelegramMessage{
        message_id: message_id,
        text: "/my_cards",
        chat: %{type: "group"} = chat,
        from: from
      }) do
    game_name = "#{chat.title}-#{chat.id}"

    case Engine.get_player_hand(game_name, from.username) do
      {:ok, player_hand} ->
        keyboard_buttons =
          for card <- player_hand.cards do
            suit = @emoji_unicode_map[card.suit]

            %Nadia.Model.KeyboardButton{text: "#{card.symbol} #{suit}"}
          end

        reply_markup = %Nadia.Model.ReplyKeyboardMarkup{
          keyboard: [keyboard_buttons],
          selective: true,
          one_time_keyboard: true
        }

        text = "You must be able to see your cards on your keyboard @#{from.username}"

        %{to: chat.id, text: text, reply_markup: reply_markup, message_id: message_id}

      {:error, :player_not_found} ->
        %{to: chat.id, text: "Sorry, but it seems you are not in this game"}

      {:error, :game_not_found} ->
        %{to: chat.id, text: "There is no game started in this group"}
    end
  end

  def process_message(%TelegramMessage{chat: chat}),
    do: %{to: chat.id, text: "Sorry, I didn't understand this message :(."}
end
