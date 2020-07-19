defmodule Engine.Round do
  defstruct players_hands: [],
            played_cards: [],
            deck: [],
            card_faced_up: nil,
            round: 1,
            next: 1,
            finished?: false,
            points: 0,
            winner: nil

  @doc """
  TODO: add docs.
  """
  def new(players) when length(players) == 4 do
    {card_faced_up, deck} = build_start_deck()
    players_hands = build_players_hands(deck, players)

    %__MODULE__{
      card_faced_up: card_faced_up,
      deck: deck,
      players_hands: players_hands
    }
  end

  defp build_start_deck do
    deck = Engine.Deck.new()
    random_position = Enum.random(0..length(deck))

    List.pop_at(deck, random_position)
  end

  defp build_players_hands(deck, players) do
    cards =
      deck
      |> Enum.take_random(12)
      |> Enum.chunk_every(3)

    for {player, index} <- Enum.with_index(players) do
      cards = Enum.at(cards, index)

      Engine.PlayerHand.new(player, cards)
    end
  end

  @doc """
  TODO: add docs.
  """
  def put_player_card(%__MODULE__{players_hands: hands} = round, player_name, card_position) do
    # TODO:
    #  * check if it is his/her turn
    # player = Enum.find(hands, & &1.player.name == player_name)
    # card = Enum.at(player.cards, card_position)
  end
end
