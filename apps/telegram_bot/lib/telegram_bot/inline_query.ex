defmodule TelegramBot.InlineQuery do
  @moduledoc """
  Provide functions for handling Telegram inline queries.
  """
  defstruct [:update_id, :from, :id, :offset, :query]

  alias TelegramBot.GameManager

  @type t :: %__MODULE__{id: String.t(), from: map(), update_id: integer(), query: String.t(), offset: String.t()}
  @type inline_query_reply :: %{inline_query_id: integer(), results: list()}

  @doc """
  Build an `InlineQuery` struct given a inline query payload.

  ### Examples

      inline_query_payload = %{
        "inline_query" => %{
          "from" => %{
            "first_name" => "Felipe",
            "id" => 111_111_111,
            "is_bot" => false,
            "language_code" => "en",
            "last_name" => "Renan",
            "username" => "feliperenan"
          },
          "id" => "3975448342490274657",
          "offset" => "",
          "query" => ""
        },
        "update_id" => 863_668_430
      }
      InlineQuery.new(inline_query_payload)
      #=> %InlineQuery{...}

  """
  @spec new(map()) :: t()
  def new(%{"inline_query" => inline_query}) do
    struct(__MODULE__, transform_to_atom_keys(inline_query))
  end

  defp transform_to_atom_keys(map) when is_map(map) do
    Map.new(map, fn
      {"from", v} -> {:from, TelegramBot.User.new(v)}
      {k, v} -> {String.to_atom(k), transform_to_atom_keys(v)}
    end)
  end

  defp transform_to_atom_keys(value), do: value

  @doc """
  Build a inline query reply according to the given `InlineQuery` struct.

  ### Examples

      InlineQuery.build_query(inline_query)
      #=> %{inline_query_id: "3975448342490274657", results: [%{...}, ]}

  """
  @spec build_reply(t()) :: inline_query_reply()
  def build_reply(%__MODULE__{from: from} = inline_query, opts \\ []) do
    get_image_by = Keyword.get(opts, :get_image_by, &ImageUploader.get_image_by/1)

    with {:ok, game_id} <- GameManager.get_game_id(user_id: from.id),
         {:ok, player_hand} <- Engine.get_player_hand(game_id, from.username),
         true <- Engine.player_turn?(game_id, from.username) do
      cards =
        for card <- player_hand.cards do
          card_id = "#{card.symbol}-#{card.suit}"
          card_image = get_image_by.(key: "#{card_id}.png")

          %Nadia.Model.InlineQueryResult.Photo{
            id: card_id,
            title: card_id,
            photo_url: card_image.url,
            thumb_url: card_image.thumb_url,
            description: "bla"
          }
        end

      %{inline_query_id: inline_query.id, results: cards}
    else
      # TODO: send something to let the user know something bad happened or that is not his turn.
      _error ->
        %{inline_query_id: inline_query.id, results: []}
    end
  end
end
