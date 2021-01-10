defmodule Engine.Round do
  defstruct played_cards: [],
            winner: nil,
            finished?: false

  alias Engine.{Card, Player}

  @type t :: %__MODULE__{
          played_cards: list(Card.t()),
          winner: Player.t() | :tied | nil,
          finished?: boolean()
        }

  @doc """
  Play the given player card in this round.
  """
  @spec play_card(t(), Player.t(), Card.t(), integer()) :: t()
  def play_card(%__MODULE__{finished?: true}, _player, _card, _total_players),
    do: {:error, :finished}

  def play_card(%__MODULE__{played_cards: played_cards} = round, player, card, total_players)
      when total_players == length(played_cards) + 1 do
    played_cards = played_cards ++ [{player, card}]

    %{round | played_cards: played_cards, finished?: true, winner: set_winner(played_cards)}
  end

  def play_card(%__MODULE__{played_cards: played_cards} = round, player, card, _total_players) do
    %{round | played_cards: played_cards ++ [{player, card}]}
  end

  defp set_winner(played_cards) do
    played_cards = Enum.sort_by(played_cards, fn {_player, card} -> card end, {:desc, Card})

    [{player_a, card_a} | [{_player_b, card_b} | _rest]] = played_cards

    case Card.compare(card_a, card_b) do
      :eq ->
        :tied

      _ ->
        player_a
    end
  end
end
