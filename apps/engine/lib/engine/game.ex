defmodule Engine.Game do
  defstruct players: [],
            matches: [],
            finished?: false,
            score: nil,
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

    %{game | matches: game.matches ++ [match]}
  end

  @doc """
  TODO: add docs.

  * check if player has the given card according to the card position otherwise it will raise an
   error in case of a invalid position.
  """
  def play_player_card(%__MODULE__{} = game, player_name, card_position) do
    %{matches: matches, players: players} = game

    case Enum.find(players, &(&1.name == player_name)) do
      nil ->
        {:error, :player_not_found}

      player ->
        matches
        |> List.last()
        |> do_play_player_card(player, card_position)
        |> case do
          %Engine.Match{finished?: true} = match ->
            matches = List.replace_at(matches, -1, match)
            new_match = Match.new(players)

            {:ok, %{game | matches: matches ++ [new_match]}}

          %Engine.Match{finished?: false} = match ->
            {:ok, %{game | matches: List.replace_at(matches, -1, match)}}
        end
    end
  end

  defp do_play_player_card(
         %Match{next_player_id: player_id} = match,
         %Player{id: player_id} = player,
         card_position
       ),
       do: Match.play_player_card(match, player, card_position)

  defp do_play_player_card(_match, _player, _card_position),
    do: {:error, :not_player_round}
end
