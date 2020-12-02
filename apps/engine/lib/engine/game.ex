defmodule Engine.Game do
  defstruct players: [],
            matches: [],
            started?: false,
            finished?: false,
            score: %{},
            winner: nil,
            blocked?: false,
            blocked_by: nil

  alias Engine.{Player, Match}

  @type t :: %__MODULE__{}
  @type answers :: :yes | :no | :increase
  @type player_error :: {:error, :player_not_found} | {:error, :not_player_turn}

  require Integer

  @players_limit 4

  def add_player(%__MODULE__{players: players}, _player_name) when length(players) >= @players_limit,
    do: {:error, :players_limit_reached}

  @doc """
  Adds the given player name to the game.
  """
  @spec add_player(t(), String.t()) :: {:ok, t()} | {:error, :player_already_joined} | {:error, :players_limit_reached}
  def add_player(%__MODULE__{players: players} = game, player_name) do
    case Enum.find(players, &(&1.name == player_name)) do
      nil ->
        number = length(players) + 1
        team_id = if Integer.is_odd(number), do: 1, else: 2
        player = Player.new(player_name, number, team_id)

        {:ok, Map.update(game, :players, player, &(&1 ++ [player]))}

      %Player{} ->
        {:error, :player_already_joined}
    end
  end

  @doc """
  TODO: add docs.
  """
  def ready?(%__MODULE__{players: players}), do: length(players) in [2, 4, 6]

  @doc """
  TODO: add docs.
  """
  def start_match(%__MODULE__{players: players} = game) do
    match = Match.new(players)
    score = build_initial_score(players)

    %{game | matches: game.matches ++ [match], score: score, started?: true}
  end

  defp build_initial_score(players) do
    [team_a_id, team_b_id] =
      players
      |> Enum.map(& &1.team_id)
      |> Enum.uniq()

    %{team_a_id => 0, team_b_id => 0}
  end

  @doc """
  Change the game state to blocked since it needs an answer from the another team.
  """
  @spec truco(t(), String.t()) :: {:ok, t()} | {:error, atom()}
  def truco(%__MODULE__{} = game, player_name) do
    current_match = List.last(game.matches)

    with :ok <- check_match_points(current_match),
         {:ok, player} <- find_player(game, player_name),
         :ok <- check_player_team(game, player),
         :ok <- check_player_round(current_match, player) do
      {:ok, %{game | blocked?: true, blocked_by: player.team_id}}
    end
  end

  @doc """
  Answer a truco request which can be either: "no", "yes" or "increase".

  ### No

  This answer will finish the match and the team who made the last truco request will be the winner
  of the match.

  ### Yes

  This answer will unblock the game and increase the points accordingly.

  ### Increase

  This answer act as another truco request, so the game will remain blocked but now for the team who
  answered "increase". Teams can be in this loop until points reachs 12, after that the game will
  be unblocked.
  """
  @spec answer(t(), String.t(), answers()) :: {:ok, t()} | {:finished, t()} | player_error()
  def answer(%__MODULE__{} = game, player_name, :no) do
    current_match = List.last(game.matches)

    with {:ok, player} <- find_player(game, player_name),
         :ok <- check_player_team(game, player),
         match <- Match.finish_match(current_match, game.blocked_by) do
      %{game | blocked?: false, blocked_by: nil}
      |> update_current_match(match)
      |> may_finish_game(match)
    end
  end

  def answer(%__MODULE__{} = game, player_name, :yes) do
    current_match = List.last(game.matches)

    with {:ok, player} <- find_player(game, player_name),
         :ok <- check_player_team(game, player),
         match <- Match.increase_points(current_match) do
      game = %{game | blocked?: false}

      {:ok, update_current_match(game, match)}
    end
  end

  def answer(%__MODULE__{} = game, player_name, :increase) do
    current_match = List.last(game.matches)

    with {:ok, player} <- find_player(game, player_name),
         :ok <- check_player_team(game, player),
         match <- Match.increase_points(current_match),
         :ok <- check_match_points(match) do
      game =
        if match.points >= 12 do
          %{game | blocked?: false, blocked_by: nil}
        else
          %{game | blocked?: true, blocked_by: player.team_id}
        end

      {:ok, update_current_match(game, match)}
    end
  end

  defp check_player_team(game, player) do
    if game.blocked_by != player.team_id do
      :ok
    else
      {:error, :not_player_turn}
    end
  end

  defp check_match_points(match) do
    if match.points >= 12 do
      {:error, :points_cannot_be_increased}
    else
      :ok
    end
  end

  @doc """
  Play the given card position for the the given player's name.

  TODO:

    * check if player has the given card according to the card position otherwise it will raise an
     error in case of a invalid position.
  """
  @spec play_player_card(t(), String.t(), integer()) :: player_error() | {:ok, t()} | {:finished, t()}
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
      {:error, :not_player_turn}
    end
  end

  defp update_current_match(game, current_match) do
    Map.update!(game, :matches, &List.replace_at(&1, -1, current_match))
  end

  defp may_finish_game(%__MODULE__{} = game, %Match{finished?: false}), do: {:ok, game}

  defp may_finish_game(%__MODULE__{} = game, %Match{finished?: true} = current_match) do
    new_score = Map.update(game.score, current_match.team_winner, 0, &(&1 + current_match.points))

    case Map.get(new_score, current_match.team_winner) do
      points when points >= 12 ->
        {:finished, %{game | finished?: true, winner: current_match.team_winner, score: new_score}}

      _points ->
        {:ok, %{game | matches: game.matches ++ [Match.new(game.players)], score: new_score}}
    end
  end
end
