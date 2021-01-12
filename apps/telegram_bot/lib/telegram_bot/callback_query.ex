defmodule TelegramBot.CallbackQuery do
  @moduledoc """
  Provide functions for handling Telegram callback queries that comes from inline queries.
  """
  defstruct [:chat_instance, :data, :from, :id, :message]

  alias TelegramBot.{GameManager, User, Message}

  @type t :: %__MODULE__{
          id: String.t(),
          from: User.t(),
          data: String.t(),
          message: Message.t(),
          chat_instance: String.t()
        }
  @type message_reply :: %{to: integer(), text: String.t(), reply_markup: map()} | :ignore

  defmodule Error do
    defexception message: "There is an error replying to callback data"
  end

  @doc """
  Build an `InlineQuery` struct given a inline query payload.

  ### Examples

      callback_query_payload = %{
        "callback_query" => %{
          "chat_instance" => "4447914486414479266",
          "data" => "no",
          "from" => %{
            "first_name" => "Felipe",
            "id" => 925_606_196,
            "is_bot" => false,
            "language_code" => "en",
            "last_name" => "Renan",
            "username" => "feeliperenan"
          },
          "id" => "3975448343267878900",
          "message" => %{...}
        },
        "update_id" => 863_668_883
      }
      CallbackQuery.new(callback_query_payload)
      #=> %CallbackQuery{...}

  """
  @spec new(map()) :: t()
  def new(%{"callback_query" => inline_query}) do
    struct(__MODULE__, transform_to_atom_keys(inline_query))
  end

  defp transform_to_atom_keys(map) when is_map(map) do
    Map.new(map, fn
      {"from", v} -> {:from, User.new(v)}
      {"message", v} -> {:message, Message.new(v)}
      {k, v} -> {String.to_atom(k), transform_to_atom_keys(v)}
    end)
  end

  defp transform_to_atom_keys(value), do: value

  # Map a card symbol to its emoji.
  @suit_to_emoji %{
    spades: "♠️",
    hearts: "❤️",
    diamonds: "♦️",
    clubs: "♣️"
  }

  @doc """
  Build a message reply according to the given `CallbackQuery` struct.

  ### Examples

      CallbackQuery.build_query(inline_query)
      #=> %{to: "3975448342490274657", text: "some message", reply_markup: %{...}}
  """
  @spec build_reply(t()) :: message_reply()
  def build_reply(%__MODULE__{from: from, data: "no", message: %Message{chat: chat}}) do
    with {:ok, game_id} <- GameManager.get_game_id(user_id: from.id),
         {:ok, game} <- Engine.answer(game_id, from.username, :no) do
      current_match = List.last(game.matches)
      previous_match = Enum.at(game.matches, length(game.matches) - 2)
      suit_emoji = @suit_to_emoji[current_match.card_faced_up.suit]
      next_player = Enum.find(game.players, &(&1.id == current_match.next_player_id))

      winners =
        for player <- game.players, player.team_id == previous_match.team_winner do
          "@" <> player.name
        end
        |> Enum.join(", ")

      text = ~s"""
      This match has been finished and won by: #{winners}

      Starting a new match....

      The card faced up is: #{current_match.card_faced_up.symbol} #{suit_emoji}

      The player who starts is: @#{next_player.name}
      """

      reply_markup = build_inline_button(text: "Make your choice")

      %{to: chat.id, text: text, reply_markup: reply_markup}
    else
      {:error, :not_player_turn} ->
        %{to: chat.id, text: "It is not your turn."}

      error ->
        error_message = "There is an error when replying a callback_query: #{inspect(error)}"

        raise __MODULE__.Error, error_message
    end
  end

  @spec build_reply(t()) :: message_reply()
  def build_reply(%__MODULE__{from: from, data: "yes", message: %Message{chat: chat}}) do
    with {:ok, game_id} <- GameManager.get_game_id(user_id: from.id),
         {:ok, game} <- Engine.answer(game_id, from.username, :yes) do
      current_match = List.last(game.matches)
      next_player = Enum.find(game.players, &(&1.id == current_match.next_player_id))

      text = ~s"""
      They have accepted your truco request. This match is worthing #{current_match.points} points.

      @#{next_player.name} play your card.
      """

      reply_markup = build_inline_button(text: "Make your choice")

      %{to: chat.id, text: text, reply_markup: reply_markup}
    else
      error ->
        error_message = "There is an error when replying a callback_query: #{inspect(error)}"

        raise __MODULE__.Error, error_message
    end
  end

  @spec build_reply(t()) :: message_reply()
  def build_reply(%__MODULE__{from: from, data: "increase", message: %Message{chat: chat}}) do
    with {:ok, game_id} <- GameManager.get_game_id(user_id: from.id),
         {:ok, %Engine.Game{blocked?: true} = game} <- Engine.answer(game_id, from.username, :increase) do
      current_match = List.last(game.matches)

      players_to_answer =
        game.players
        |> Enum.reject(&(&1.team_id == game.blocked_by))
        |> Enum.map(&"@#{&1.name}")
        |> Enum.join(", ")

      text = ~s"""
      There is a increase truco request coming from @#{from.username}

      #{players_to_answer} choose one of the options below:
      """

      increase_text =
        case current_match.points do
          9 -> "Twelve"
          6 -> "Nine"
        end

      inline_buttons = [
        %Nadia.Model.InlineKeyboardButton{text: "Yes", callback_data: "yes"},
        %Nadia.Model.InlineKeyboardButton{text: "No", callback_data: "no"},
        %Nadia.Model.InlineKeyboardButton{text: increase_text, callback_data: "increase"}
      ]

      reply_markup = %Nadia.Model.InlineKeyboardMarkup{inline_keyboard: [inline_buttons]}

      %{to: chat.id, text: text, reply_markup: reply_markup}
    else
      # Game reached 12 points so it is unblocked now and ready to play.
      {:ok, %Engine.Game{blocked?: false} = game} ->
        current_match = List.last(game.matches)
        next_player = Enum.find(game.players, &(&1.id == current_match.next_player_id))

        text = ~s"""
        They have accepted your truco request. This match is worthing #{current_match.points} points.

        @#{next_player.name} play your card.
        """

        reply_markup = build_inline_button(text: "Make your choice")

        %{to: chat.id, text: text, reply_markup: reply_markup}

      {:error, :points_cannot_be_increased} ->
        %{to: chat.id, text: "Points cannot be increased anymore. You should either accept or refuse this request."}

      error ->
        error_message = "There is an error when replying a callback_query: #{inspect(error)}"

        raise __MODULE__.Error, error_message
    end
  end

  defp build_inline_button(text: text) do
    inline_buttons = [
      %Nadia.Model.InlineKeyboardButton{text: text, switch_inline_query_current_chat: ""}
    ]

    %Nadia.Model.InlineKeyboardMarkup{inline_keyboard: [inline_buttons]}
  end
end
