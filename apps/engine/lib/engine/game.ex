defmodule Engine.Game do
  defstruct players: [],
            rounds: [],
            current_round: 0,
            finished?: false,
            score: nil,
            winner: nil

  alias Engine.{Player, Round}

  require Integer

  @doc """
  TODO: add docs.
  """
  def add_player(%__MODULE__{players: players} = game, player_name) when length(players) < 4 do
    number = length(players) + 1
    team_id = if Integer.is_odd(number), do: 1, else: 2
    player = Player.new(player_name, number, team_id)

    {:ok, Map.update(game, :players, player, &(&1 ++ [player]))}
  end

  def add_player(%__MODULE__{players: players}, _player_name) when length(players) == 4 do
    {:error, "This game has already 4 players."}
  end

  @doc """
  TODO: add docs.
  """
  def ready?(%__MODULE__{players: players}), do: length(players) == 4

  @doc """
  TODO: add docs.
  """
  def start_round(%__MODULE__{players: players} = game) do
    round = Round.new(players)

    %{game | rounds: game.rounds ++ [round]}
  end

  @doc """
  TODO: add docs.
  # * put the player card in the played cards in the current round ✅
  # * check if someone finished this round and,
  #  * if so:
  #   * check who won the round.
  #   * increase points for the round winner
  #   * check if the player has won the game
  #   * start another round if there is no winner
  #  if doesn't:
  #   * set next player according to his/her number.
  # * If someone win the round, he will be the one that will start. Check if number of the players
  #   should be changed.
  """
  def put_player_card(%__MODULE__{} = game, player_name, card_position) do
    %{rounds: rounds, players: players, current_round: current_round} = game

    case Enum.find(players, &(&1.name == player_name)) do
      nil ->
        {:error, :player_not_found}

      player ->
        %Engine.Round{next_player_id: next_player_id} = Enum.at(rounds, current_round)

        if next_player_id == player.id do
          rounds =
            List.update_at(
              rounds,
              current_round,
              &Round.put_player_card(&1, player, card_position)
            )

          {:ok, %{game | rounds: rounds}}
        else
          {:error, :not_player_turn}
        end
    end
  end
end
