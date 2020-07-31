defmodule Engine.Round do
  defstruct players_hands: [],
            deck: [],
            card_faced_up: nil,
            turns: [],
            next_player_id: 1,
            finished?: false,
            points: 1,
            team_winner: nil,
            total_players: 0

  alias Engine.{Card, Deck, Player, PlayerHand, Turn}

  @doc """
  TODO: add docs.
  """
  def new(players) when length(players) == 4 do
    {card_faced_up, deck} = build_start_deck()

    players_hands =
      deck
      |> set_special(card_faced_up)
      |> build_players_hands(players)

    %__MODULE__{
      card_faced_up: card_faced_up,
      deck: deck,
      players_hands: players_hands,
      total_players: length(players_hands),
      turns: [%Turn{}]
    }
  end

  defp set_special(deck, card_faced_up),
    do: for(card <- deck, do: Card.set_special(card, card_faced_up))

  defp build_start_deck do
    deck = Deck.new()
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

      PlayerHand.new(player, cards)
    end
  end

  @doc """
  TODO: add docs.
  """
  def play_player_card(%__MODULE__{} = round, player, card_position) do
    %{next_player_id: next_player_id, total_players: total_players} = round

    {card, players_hands} = discard_player_card(round, player, card_position)
    {turn, turns} = play_card_in_turn(round, player, card)

    %{
      round
      | turns: turns,
        players_hands: players_hands,
        next_player_id: set_next_player(turn, next_player_id, total_players)
    }
    |> check_team_winner()
  end

  # Discard the given card position form the player's hands.
  #
  # Returns a tuple with the discarded card and updated players hands.
  defp discard_player_card(%__MODULE__{players_hands: players_hands}, player, card_position) do
    player_hand = Enum.find(players_hands, &(&1.player.name == player.name))
    {card, cards} = List.pop_at(player_hand.cards, card_position)

    players_hands =
      for player_hand <- players_hands do
        if player_hand.player.name == player.name do
          %{player_hand | cards: cards}
        else
          player_hand
        end
      end

    {card, players_hands}
  end

  # Play the player's card in the correct turn.
  #
  # This function will check if the last turn has been finished. If so, a new one will be started.
  defp play_card_in_turn(%__MODULE__{} = round, player, card) do
    case List.last(round.turns) do
      %Turn{finished?: true} ->
        turn = Turn.play_card(%Turn{}, player, card, round.total_players)

        {turn, round.turns ++ [turn]}

      %Turn{finished?: false} = turn ->
        turn = Turn.play_card(turn, player, card, round.total_players)

        {turn, List.replace_at(round.turns, -1, turn)}
    end
  end

  defp set_next_player(%Turn{winner: nil}, next_player_id, total_players)
       when total_players == next_player_id,
       do: 1

  defp set_next_player(%Turn{winner: nil}, next_player_id, total_players)
       when next_player_id < total_players,
       do: next_player_id + 1

  defp set_next_player(%Turn{winner: :tied}, next_player_id, total_players)
       when next_player_id < total_players,
       do: 1

  defp set_next_player(%Turn{winner: winner}, _, _), do: winner.id

  # there is no team winner when only the first turn has been played.
  defp check_team_winner(%__MODULE__{turns: [_turn]} = round),
    do: %{round | finished?: false}

  # there is no team winner when the second round is not finished
  defp check_team_winner(%__MODULE__{turns: [_turn, %Turn{finished?: false}]} = round),
    do: %{round | finished?: false}

  # when first round is tied the second winner is the team winner.
  defp check_team_winner(
         %__MODULE__{
           turns: [
             %Turn{winner: :tied},
             %Turn{winner: winner}
           ]
         } = round
       ),
       do: %{round | finished?: true, team_winner: winner.team_id}

  # when the second round is tied the first winner is the team winner.
  defp check_team_winner(
         %__MODULE__{
           turns: [
             %Turn{winner: winner},
             %Turn{winner: :tied}
           ]
         } = round
       ),
       do: %{round | finished?: true, team_winner: winner.team_id}

  # when the same team win the first two rounds they will be the winner.
  defp check_team_winner(
         %__MODULE__{
           turns: [
             %Turn{winner: %Player{team_id: team_id}},
             %Turn{winner: %Player{team_id: team_id}}
           ]
         } = round
       ),
       do: %{round | finished?: true, team_winner: team_id}

  # there is no winner when both teams win one round.
  defp check_team_winner(
         %__MODULE__{
           turns: [
             %Turn{winner: %Player{team_id: _first_id}},
             %Turn{winner: %Player{team_id: _second_id}}
           ]
         } = round
       ),
       do: %{round | finished?: false}

  # there is no winner when the third round is not finished.
  defp check_team_winner(
         %__MODULE__{
           turns: [
             %Turn{},
             %Turn{},
             %Turn{finished?: false}
           ]
         } = round
       ),
       do: %{round | finished?: false}

  # when one team win the first and third round they will be the winner.
  defp check_team_winner(
         %__MODULE__{
           turns: [
             %Turn{winner: %Player{team_id: team_id}},
             %Turn{winner: %Player{team_id: _team_id}},
             %Turn{winner: %Player{team_id: team_id}}
           ]
         } = round
       ),
       do: %{round | finished?: true, team_winner: team_id}

  # when one team win the second and third round they will be the winner.
  defp check_team_winner(
         %__MODULE__{
           turns: [
             %Turn{winner: %Player{team_id: _team_id}},
             %Turn{winner: %Player{team_id: team_id}},
             %Turn{winner: %Player{team_id: team_id}}
           ]
         } = round
       ),
       do: %{round | finished?: true, team_winner: team_id}
end
