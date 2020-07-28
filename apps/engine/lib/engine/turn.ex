defmodule Engine.Turn do
  defstruct played_cards: [],
            winner: nil,
            finished?: false

  alias Engine.Card

  @doc """
  TODO: add doc
  """
  def play_card(%__MODULE__{finished?: true}, _player, _card, _total_players),
    do: {:error, :finished}

  def play_card(%__MODULE__{played_cards: played_cards} = turn, player, card, total_players)
      when total_players == length(played_cards) + 1 do
    played_cards = played_cards ++ [{player, card}]

    %{turn | played_cards: played_cards, finished?: true, winner: set_winner(played_cards)}
  end

  def play_card(%__MODULE__{played_cards: played_cards} = turn, player, card, _total_players) do
    %{turn | played_cards: played_cards ++ [{player, card}]}
  end

  defp set_winner(played_cards) do
    played_cards = Enum.sort_by(played_cards, fn {_player, card} -> card end, {:desc, Card})

    # TODO: set tied when last two cards are the same strength
    {player, _card} = List.first(played_cards)

    player.number
  end
end
