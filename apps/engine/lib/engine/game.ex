defmodule Engine.Game do
  defstruct players: [],
            matches: [],
            finished?: false,
            score: %{},
            winner: nil

  alias Engine.{Player, Match}

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
  def start_match(%__MODULE__{players: players} = game) do
    match = Match.new(players)
    score = build_initial_score(players)

    %{game | matches: game.matches ++ [match], score: score}
  end

  defp build_initial_score(players) do
    [team_a_id, team_b_id] =
      players
      |> Enum.map(& &1.team_id)
      |> Enum.uniq()

    %{team_a_id => 0, team_b_id => 0}
  end

  @doc """
  TODO: add docs.

  * check if player has the given card according to the card position otherwise it will raise an
   error in case of a invalid position.
  """
  def play_player_card(%__MODULE__{} = game, player_name, card_position) do
    current_match = List.last(game.matches)

    with {:ok, player} <- find_player(game, player_name),
         :ok <- check_player_round(current_match, player),
         current_match <- Match.play_player_card(current_match, player, card_position) do
      game
      |> update_current_match(current_match)
      |> may_finish_game(current_match)
    end
  end

  defp find_player(game, player_name) do
    case Enum.find(game.players, &(&1.name == player_name)) do
      nil ->
        {:error, :player_not_found}

      player ->
        {:ok, player}
    end
  end

  defp check_player_round(match, player) do
    if match.next_player_id == player.id do
      :ok
    else
      {:error, :not_player_round}
    end
  end

  defp update_current_match(game, current_match) do
    Map.update!(game, :matches, &List.replace_at(&1, -1, current_match))
  end

  defp may_finish_game(%__MODULE__{} = game, %Match{finished?: false}), do: {:ok, game}

  defp may_finish_game(
         %__MODULE__{score: score, players: players, matches: matches} = game,
         %Match{finished?: true} = current_match
       ) do
    new_score = Map.update(score, current_match.team_winner, 0, &(&1 + current_match.points))

    case Map.get(new_score, current_match.team_winner) do
      points when points >= 12 ->
        {:finished,
         %{game | finished?: true, winner: current_match.team_winner, score: new_score}}

      _points ->
        {:ok, %{game | matches: matches ++ [Match.new(players)], score: new_score}}
    end
  end
end
