defmodule TelegramBot.Message do
  @moduledoc """
  Provide functions for handling Telegram messages.
  """
  alias TelegramBot.{Chat, GameManager, User}

  defstruct [:chat, :date, :from, :message_id, :text]

  @type t() :: %__MODULE__{
          chat: %Chat{},
          date: integer(),
          from: %User{},
          message_id: integer(),
          text: String.t()
        }
  @type message_reply :: %{to: integer(), text: String.t()} | list(map())

  # Map a card symbol to its emoji.
  @suit_to_emoji %{
    spades: "♠️",
    hearts: "❤️",
    diamonds: "♦️",
    clubs: "♣️"
  }

  @doc """
  Builds a `Message` struct from the given message payload.

  ### Examples

    message_payload = %{
       "message" => %{
         "chat" => %{
           "all_members_are_administrators" => true,
           "id" => -419_752_573,
           "title" => "truco-test",
           "type" => "group"
         },
         "date" => 1_605_212_571,
         "entities" => [%{"length" => 19, "offset" => 0, "type" => "bot_command"}],
         "from" => %{
           "first_name" => "Felipe",
           "id" => 925_606_196,
           "is_bot" => false,
           "language_code" => "en",
           "last_name" => "Renan"
         },
         "message_id" => 16,
         "text" => "/start@ex_truco_bot"
       },
       "update_id" => 863_667_915
     }
     Message.new(message_payload)
     #=> %__MODULE__{...}
  """
  @spec new(map()) :: t()
  def new(%{"message" => message}) do
    message_payload =
      message
      |> transform_to_atom_keys()
      |> remove_bot_suffix_from_text()

    struct(__MODULE__, message_payload)
  end

  defp transform_to_atom_keys(map) when is_map(map) do
    Map.new(map, fn
      {"from", v} -> {:from, User.new(v)}
      {"chat", v} -> {:chat, Chat.new(v)}
      {k, v} -> {String.to_atom(k), transform_to_atom_keys(v)}
    end)
  end

  defp transform_to_atom_keys(value), do: value

  defp remove_bot_suffix_from_text(%{text: text} = message),
    do: %{message | text: String.replace(text, "@ex_truco_bot", "")}

  defp remove_bot_suffix_from_text(message), do: message

  @doc """
  Build a message reply according to the given `Message` struct.

  ### Examples

      Message.build_query(message)
      #=> %{to: "3975448342490274657", text: "some message as reply"}

  """
  @spec build_reply(t()) :: message_reply()
  def build_reply(%__MODULE__{text: "/new", chat: %{type: "group"} = chat}) do
    game_id = GameManager.new_game(chat)

    text =
      case Engine.new_game(game_id) do
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

  def build_reply(%__MODULE__{text: "/join", chat: %{type: "group"} = chat, from: from}) do
    case GameManager.add_user(chat, from.id) do
      {:ok, game_id} ->
        text =
          case Engine.join_player(game_id, from.username) do
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

      {:error, :duplicated_join} ->
        %{to: chat.id, text: "You have already joined a game."}
    end
  end

  def build_reply(%__MODULE__{text: "/start", chat: %{type: "group"} = chat, from: from}) do
    with {:ok, game_id} <- GameManager.get_game_id(user_id: from.id),
         {:ok, %Engine.Game{} = game} <- Engine.start_game(game_id) do
      current_match = List.last(game.matches)
      player_turn = Enum.find(game.players, &(&1.id == current_match.next_player_id))
      suit_emoji = @suit_to_emoji[current_match.card_faced_up.suit]

      text = ~s"""
      The game has been started

      The card faced up is: #{current_match.card_faced_up.symbol} #{suit_emoji}
      The player who starts is: @#{player_turn.name}
      """

      inline_buttons = [
        %Nadia.Model.InlineKeyboardButton{
          text: "Make your choice",
          switch_inline_query_current_chat: ""
        }
      ]

      reply_markup = %Nadia.Model.InlineKeyboardMarkup{
        inline_keyboard: [inline_buttons]
      }

      %{to: chat.id, text: text, reply_markup: reply_markup}
    else
      {:error, :game_already_started} ->
        %{to: chat.id, text: "Game has been started already."}

      {:error, :not_found} ->
        %{to: chat.id, text: "Game is not found. Make sure players have been joined the game with /join."}

      {:error, _error_message} ->
        %{to: chat.id, text: "There is something wrong so I couldn't start the game :("}
    end
  end

  def build_reply(%__MODULE__{chat: %{type: "group"} = chat}) do
    %{to: chat.id, text: "Sorry, I didn't understand this message :(."}
  end
end
