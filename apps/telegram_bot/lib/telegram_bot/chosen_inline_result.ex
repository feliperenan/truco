defmodule TelegramBot.ChosenInlineResult do
  @moduledoc """
  Provide functions for handling Telegram chosen inline result from inline queries.
  """
  defstruct [:from, :result_id, :query]

  alias TelegramBot.{GameManager, User}

  require Logger

  @type t :: %__MODULE__{
          result_id: String.t(),
          from: User.t(),
          query: String.t()
        }
  @type message_reply :: %{to: integer(), text: String.t(), reply_markup: map()}

  defmodule Error do
    defexception message: "There is an error replying to a chosen inline result"
  end

  @doc """
  Build an `ChosenInlineQuery` struct given a inline query payload.

  ### Examples

      chosen_inline_result = %{
        "chosen_inline_result" => %{
          "from" => %{
            "first_name" => "Felipe",
            "id" => 111_111_111,
            "is_bot" => false,
            "language_code" => "en",
            "last_name" => "Renan",
            "username" => "feeliperenan"
          },
          "query" => "",
          "result_id" => "Q-clubs"
        },
        "update_id" => 863_668_693
      }
      ChosenInlineResult.new(chosen_inline_result)
      #=> %ChosenInlineResult{...}

  """
  @spec new(map()) :: t()
  def new(%{"chosen_inline_result" => chosen_inline_result}) do
    struct(__MODULE__, transform_to_atom_keys(chosen_inline_result))
  end

  defp transform_to_atom_keys(map) when is_map(map) do
    Map.new(map, fn
      {"from", v} -> {:from, User.new(v)}
      {k, v} -> {String.to_atom(k), transform_to_atom_keys(v)}
    end)
  end

  defp transform_to_atom_keys(value), do: value

  @doc """
  Build a message reply according to the given `ChosenInlineResult` struct.

  This message likely comes when a User choose a card on inline mode. The `card_id` will be present in the `result_id`,
  so this is going to be parsed back in order to find the User card and play this card in the game.

  ### Examples

      ChosenInlineResult.build_query(chosen_inline_result)
      #=> %{inline_query_id: "3975448342490274657", results: [%{...}, ]}

  """
  @spec build_reply(t()) :: map()
  def build_reply(%__MODULE__{from: user, result_id: result_id}) when is_binary(result_id) do
    with {:ok, game_id} <- GameManager.get_game_id(user_id: user.id),
         {:ok, card_position} <- get_card_position(game_id, user.username, result_id),
         {:ok, game, current_match, next_player} <- play_player_card(game_id, user.username, card_position) do
      text =
        if new_match?(current_match) do
          new_match_text(next_player, current_match, game)
        else
          new_round_text(next_player, current_match)
        end

      reply_markup = build_inline_button(text: "Make your choice")

      %{to: game_id, text: text, reply_markup: reply_markup}
    else
      error ->
        error_message = "There is an error when replying a chosen inline result: #{inspect(error)}"

        raise __MODULE__.Error, error_message
    end
  end

  defp get_card_position(game_id, username, result_id) do
    with {:ok, {symbol, suit}} <- parse_result_id(result_id),
         {:ok, player_hand} <- Engine.get_player_hand(game_id, username) do
      case Enum.find_index(player_hand.cards, &(&1.suit == suit and &1.symbol == symbol)) do
        nil ->
          {:error, :card_not_found}

        card_index ->
          {:ok, card_index}
      end
    end
  end

  defp parse_result_id(text) do
    case String.split(text, "-") do
      [symbol, suit] ->
        {:ok, {symbol, String.to_existing_atom(suit)}}

      _unknown_result ->
        {:error, :unkown_result}
    end
  end

  def play_player_card(game_id, username, card_position) do
    with {:ok, game} <- Engine.play_player_card(game_id, username, card_position) do
      current_match = List.last(game.matches)
      next_player = Enum.find(game.players, &(&1.id == current_match.next_player_id))
      {:ok, game, current_match, next_player}
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

  # Map a card symbol to its emoji.
  @suit_to_emoji %{
    spades: "♠️",
    hearts: "❤️",
    diamonds: "♦️",
    clubs: "♣️"
  }

  defp new_match_text(next_player, current_match, game) do
    previous_match = Enum.at(game.matches, length(game.matches) - 2)
    suit_emoji = @suit_to_emoji[current_match.card_faced_up.suit]

    winners =
      for player <- game.players, player.team_id == previous_match.team_winner do
        "@" <> player.name
      end
      |> Enum.join(", ")

    ~s"""
    This match has been finished and won by: #{winners}

    Starting a new match....

    The card faced up is: #{current_match.card_faced_up.symbol} #{suit_emoji}

    The player who starts is: @#{next_player.name}
    """
  end

  defp new_round_text(next_player, current_match) do
    case List.last(current_match.rounds) do
      %Engine.Round{finished?: true, winner: :tied} ->
        "The game is tied. Now is @#{next_player.name} turn."

      %Engine.Round{finished?: true} ->
        "@#{next_player.name} won this turn."

      %Engine.Round{finished?: false} ->
        "Now is @#{next_player.name} turn."
    end
  end

  def build_inline_button(text: text) do
    inline_buttons = [
      %Nadia.Model.InlineKeyboardButton{text: text, switch_inline_query_current_chat: ""}
    ]

    %Nadia.Model.InlineKeyboardMarkup{inline_keyboard: [inline_buttons]}
  end
end
