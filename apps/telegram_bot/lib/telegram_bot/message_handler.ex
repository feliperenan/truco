defmodule TelegramBot.MessageHandler do
  alias TelegramBot.TelegramMessage

  @type chat_response :: %{to: integer(), text: String.t()} | list(map())

  @suit_to_emoji %{
    spades: "♠️",
    hearts: "❤️",
    diamonds: "♦️",
    clubs: "♣️"
  }

  @emoji_to_suit %{
    "♠️" => :spades,
    "❤️" => :hearts,
    "♦️" => :diamonds,
    "♣️" => :clubs
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
        suit_emoji = @suit_to_emoji[current_match.card_faced_up.suit]

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
            suit = @suit_to_emoji[card.suit]

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

  def process_message(%TelegramMessage{chat: %{type: "group"} = chat, from: from, text: text}) do
    game_name = "#{chat.title}-#{chat.id}"

    case parse_message_to_card(text) do
      {symbol, suit} ->
        text = find_player_card_and_play(game_name, from.username, symbol, suit)

        %{to: chat.id, text: text}

      _random_text ->
        %{to: chat.id, text: "Sorry, I didn't understand this message :(."}
    end
  end

  defp parse_message_to_card(text) do
    [symbol, emoji_suit] = String.split(text)
    suit = Map.get(@emoji_to_suit, emoji_suit)

    if is_nil(suit), do: text, else: {symbol, suit}
  end

  defp find_player_card_and_play(game_name, username, symbol, suit) do
    case Engine.get_player_hand(game_name, username) do
      {:ok, player_hand} ->
        card_position = Enum.find_index(player_hand.cards, &(&1.suit == suit and &1.symbol == symbol))
        play_player_card(game_name, username, card_position)

      {:error, :player_not_found} ->
        "Sorry, but it seems you are not in this game"

      {:error, :game_not_found} ->
        "There is no game started in this group"
    end
  end

  defp play_player_card(game_name, username, card_position) do
    case Engine.play_player_card(game_name, username, card_position) do
      {:ok, game} ->
        current_match = List.last(game.matches)
        player_turn = Enum.find(game.players, &(&1.id == current_match.next_player_id))

        if new_match?(current_match) do
          new_match_text(player_turn, current_match, game)
        else
          new_round_text(player_turn, current_match)
        end

      {:finished, _game} ->
        "I can't tell who won the game yet..."

      {:error, :not_player_turn} ->
        "It is not your turn. Wait for your turn and then play your card."
    end
  end

  defp new_match?(match) do
    case match.rounds do
      [%Engine.Round{finished?: false, played_cards: []}] ->
        true

      _rounds ->
        false
    end
  end

  def new_match_text(player_turn, current_match, game) do
    previous_match = Enum.at(game.matches, length(game.matches) - 2)
    suit_emoji = @suit_to_emoji[current_match.card_faced_up.suit]

    winners =
      for player <- game.players, player.team_id == previous_match.team_winner do
        "@" <> player.name
      end
      |> Enum.join(", ")

    ~s"""
    This match has been finished and won by: #{winners}

    Starting a new round.

    The card faced up is: #{current_match.card_faced_up.symbol} #{suit_emoji}
    The player who starts is: @#{player_turn.name}

    To check your cards, send /my_cards
    """
  end

  defp new_round_text(player_turn, current_match) do
    case List.last(current_match.rounds) do
      %Engine.Round{finished?: true, winner: :tied} ->
        "The game is tied. Now is @#{player_turn.name} turn. Send /my_cards and play your card."

      %Engine.Round{finished?: true} ->
        "@#{player_turn.name} won this turn. Send /my_cards and play your card."

      %Engine.Round{finished?: false} ->
        "Now is @#{player_turn.name} turn. Send /my_cards and play your card."
    end
  end
end
