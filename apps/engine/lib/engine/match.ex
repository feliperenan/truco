defmodule Engine.Match do
  defstruct players_hands: [],
            deck: [],
            card_faced_up: nil,
            rounds: [],
            next_player_id: 1,
            finished?: false,
            points: 1,
            team_winner: nil,
            total_players: 0

  alias Engine.{Card, Deck, Player, PlayerHand, Round}

  @type t :: %__MODULE__{}

  @players_limit [2, 4]

  @doc """
  Start a new match according to the given players.

  This function will: get a shuffled deck of cards, face up one random card, set the special cards,
  build players hands and, start the first round.

  ### Examples

      players = [
        %Player{id: 1, name: "Felipe", team_id: 1},
        %Player{id: 2, name: "Carlos", team_id: 2}
      ]
      Match.new(players)
      #=> %Match{}

  """
  @spec new(list(Player.t())) :: t()
  def new(players) when length(players) in @players_limit do
    {card_faced_up, deck} = build_start_deck()
    deck = set_special(deck, card_faced_up)
    players_hands = build_players_hands(deck, players)

    %__MODULE__{
      card_faced_up: card_faced_up,
      deck: deck,
      players_hands: players_hands,
      total_players: length(players_hands),
      rounds: [%Round{}]
    }
  end

  def new(players) when is_list(players) do
    message = """
    A match does not support #{length(players)} players. The total of players must be 2 or 4.
    """

    raise ArgumentError, message: message
  end

  defp set_special(deck, card_faced_up),
    do: for(card <- deck, do: Card.set_special(card, card_faced_up))

  defp build_start_deck do
    deck = Deck.new()
    random_position = Enum.random(0..(length(deck) - 1))

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
  def play_player_card(%__MODULE__{} = match, player, card_position) do
    %{next_player_id: next_player_id, total_players: total_players} = match

    {card, players_hands} = discard_player_card(match, player, card_position)
    {round, rounds} = play_card_in_round(match, player, card)

    %{
      match
      | rounds: rounds,
        players_hands: players_hands,
        next_player_id: set_next_player(round, next_player_id, total_players)
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

  # Play the player's card in the correct round.
  #
  # This function will check if the last round has been finished. If so, a new one will be started.
  defp play_card_in_round(%__MODULE__{} = match, player, card) do
    case List.last(match.rounds) do
      %Round{finished?: true} ->
        round = Round.play_card(%Round{}, player, card, match.total_players)

        {round, match.rounds ++ [round]}

      %Round{finished?: false} = round ->
        round = Round.play_card(round, player, card, match.total_players)

        {round, List.replace_at(match.rounds, -1, round)}
    end
  end

  defp set_next_player(%Round{winner: nil}, next_player_id, total_players)
       when total_players == next_player_id,
       do: 1

  defp set_next_player(%Round{winner: nil}, next_player_id, total_players)
       when next_player_id < total_players,
       do: next_player_id + 1

  defp set_next_player(%Round{winner: :tied}, next_player_id, _total_players),
    do: next_player_id

  defp set_next_player(%Round{winner: winner}, _, _), do: winner.id

  # there is no team winner when only the first round has been played.
  defp check_team_winner(%__MODULE__{rounds: [_round]} = match),
    do: %{match | finished?: false}

  # there is no team winner when the second match is not finished.
  defp check_team_winner(%__MODULE__{rounds: [_round, %Round{finished?: false}]} = match),
    do: %{match | finished?: false}

  # there is no team winner when the first and second match is tied.
  defp check_team_winner(
         %__MODULE__{
           rounds: [
             %Round{winner: :tied},
             %Round{winner: :tied}
           ]
         } = match
       ),
       do: %{match | finished?: false}

  # when first match is tied the second winner is the team winner.
  defp check_team_winner(
         %__MODULE__{
           rounds: [
             %Round{winner: :tied},
             %Round{winner: winner}
           ]
         } = match
       ),
       do: %{match | finished?: true, team_winner: winner.team_id}

  # when the second match is tied the first winner is the team winner.
  defp check_team_winner(
         %__MODULE__{
           rounds: [
             %Round{winner: winner},
             %Round{winner: :tied}
           ]
         } = match
       ),
       do: %{match | finished?: true, team_winner: winner.team_id}

  # when the same team win the first two rounds they will be the winner.
  defp check_team_winner(
         %__MODULE__{
           rounds: [
             %Round{winner: %Player{team_id: team_id}},
             %Round{winner: %Player{team_id: team_id}}
           ]
         } = match
       ),
       do: %{match | finished?: true, team_winner: team_id}

  # there is no winner when both teams win one round.
  defp check_team_winner(
         %__MODULE__{
           rounds: [
             %Round{finished?: true},
             %Round{finished?: true}
           ]
         } = match
       ),
       do: %{match | finished?: false}

  # there is no winner when the third round is not finished.
  defp check_team_winner(
         %__MODULE__{
           rounds: [
             %Round{},
             %Round{},
             %Round{finished?: false}
           ]
         } = match
       ),
       do: %{match | finished?: false}

  # when one team win the first and third round they will be the winner.
  defp check_team_winner(
         %__MODULE__{
           rounds: [
             %Round{winner: %Player{team_id: team_id}},
             %Round{winner: %Player{team_id: _team_id}},
             %Round{winner: %Player{team_id: team_id}}
           ]
         } = match
       ),
       do: %{match | finished?: true, team_winner: team_id}

  # when one team win the second and third round they will be the winner.
  defp check_team_winner(
         %__MODULE__{
           rounds: [
             %Round{winner: %Player{team_id: _team_id}},
             %Round{winner: %Player{team_id: team_id}},
             %Round{winner: %Player{team_id: team_id}}
           ]
         } = match
       ),
       do: %{match | finished?: true, team_winner: team_id}

  # when the third round is tied the team winner will be the team who won the first round.
  defp check_team_winner(
         %__MODULE__{
           rounds: [
             %Round{winner: %Player{team_id: team_id}},
             %Round{winner: %Player{team_id: _team_id}},
             %Round{winner: :tied}
           ]
         } = match
       ),
       do: %{match | finished?: true, team_winner: team_id}

  # when first and second round is tied, the team winner will be the one who won the third one.
  defp check_team_winner(
         %__MODULE__{
           rounds: [
             %Round{winner: :tied},
             %Round{winner: :tied},
             %Round{winner: %Player{team_id: team_id}}
           ]
         } = match
       ),
       do: %{match | finished?: true, team_winner: team_id}
end
