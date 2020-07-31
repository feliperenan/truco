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

  * check if player has the given card according to the card position otherwise it will raise an
   error in case of a invalid position.
  """
  def play_player_card(%__MODULE__{} = game, player_name, card_position) do
    %{rounds: rounds, players: players} = game

    case Enum.find(players, &(&1.name == player_name)) do
      nil ->
        {:error, :player_not_found}

      player ->
        rounds
        |> List.last()
        |> do_play_player_card(player, card_position)
        |> case do
          %Engine.Round{finished?: true} = round ->
            rounds = List.replace_at(rounds, -1, round)
            new_round = Round.new(players)

            {:ok, %{game | rounds: rounds ++ [new_round]}}

          %Engine.Round{finished?: false} = round ->
            {:ok, %{game | rounds: List.replace_at(rounds, -1, round)}}
        end
    end
  end

  defp do_play_player_card(
         %Round{next_player_id: player_id} = round,
         %Player{id: player_id} = player,
         card_position
       ),
       do: Round.play_player_card(round, player, card_position)

  defp do_play_player_card(_round, _player, _card_position),
    do: {:error, :not_player_turn}
end
