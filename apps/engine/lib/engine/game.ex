defmodule Engine.Game do
  defstruct players: [],
            rounds: [],
            finished?: false,
            score: nil,
            winner: nil

  alias Engine.{Player, Round}

  @doc """
  TODO: add docs.
  """
  def add_player(%__MODULE__{players: players} = game, player_name) when length(players) < 4 do
    player = Player.new(player_name, length(players) + 1)

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
  # put the player card in the played cards in the current round
  # check if someone finished this round and,
  #  * if so:
  #   * check who won the round.
  #   * increase points for the round winner
  #   * check if the player has won the game
  #   * start another round if there is no winner
  #  if doesn't:
  #   * set next player according to his/her number.
  """
  def put_player_card(%__MODULE__{rounds: rounds}, player_name, card_position) do
    round = List.last(rounds)

    Round.put_player_card(round, player_name, card_position)
  end
end
