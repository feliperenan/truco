defmodule Engine do
  @moduledoc """
  Documentation for `Engine`.
  """

  alias Engine.{Game, GameSupervisor, GameServer, PlayerHand}

  @type game_id :: String.t()
  @type player_name :: String.t()
  @type answers :: Engine.Game.answers()

  @doc """
  Find or create a `GameServer` process under `GameSupervisor`.

  ### Examples

    iex> Engine.new_game("my-game")
    {:ok, "my-game"}

  """
  @spec new_game(game_id()) :: {:ok, game_id()} | {:error, String.t()}
  def new_game(name) do
    if GameSupervisor.game_exists?(name) do
      {:error, "there is already a game with this name: #{name}"}
    else
      {:ok, _pid} = GameSupervisor.create_game(name)

      {:ok, name}
    end
  end

  @spec join_player(game_id(), player_name()) ::
          {:ok, Game.t()}
          | {:error, :game_not_found}
          | {:error, :player_already_joined}
          | {:error, :players_limit_reached}
  def join_player(game_id, player) do
    if GameSupervisor.game_exists?(game_id) do
      GameServer.join_player(game_id, player)
    else
      {:error, :game_not_found}
    end
  end

  @spec start_game(game_id()) ::
          {:ok, Engine.Game.t()}
          | {:error, :game_already_started}
          | {:error, :game_not_found}
          | {:error, String.t()}
  def start_game(game_id) do
    if GameSupervisor.game_exists?(game_id) do
      GameServer.start_game(game_id)
    else
      {:error, :game_not_found}
    end
  end

  @spec play_player_card(game_id(), player_name(), integer()) :: {:ok, Game.t()}
  defdelegate play_player_card(game_id, player_name, card_position), to: GameServer

  @spec truco(game_id(), player_name()) ::
          {:ok, Game.t()} | {:finished, Game.t()} | Game.player_error()
  defdelegate truco(game, player_name), to: GameServer

  @spec answer(game_id(), player_name(), answers()) ::
          {:ok, Game.t()} | {:finished, Game.t()} | Game.player_error()
  defdelegate answer(game, player_name, answer), to: GameServer

  @doc """
  Returns a game given its id.
  """
  @spec get_game(game_id()) :: Game.t()
  def get_game(game_id), do: GameServer.get(game_id)

  @doc """
  Returns true if it is the given player turn.
  """
  @spec player_turn?(game_id(), player_name()) :: boolean() | {:error, :game_not_found}
  def player_turn?(game_id, player_name) do
    game = GameServer.get(game_id)
    current_match = List.last(game.matches)
    player = Enum.find(game.players, %{id: nil}, &(&1.name == player_name))

    current_match.next_player_id == player.id
  end

  @doc """
  Returns a player hand given the game_id and player_name.
  """
  @spec get_player_hand(game_id(), player_name()) ::
          {:ok, PlayerHand.t()}
          | {:error, :game_not_found}
          | {:error, :player_not_found}
  def get_player_hand(game_id, player_name) do
    if GameSupervisor.game_exists?(game_id) do
      game = GameServer.get(game_id)
      current_match = List.last(game.matches)

      case Enum.find(current_match.players_hands, &(&1.player.name == player_name)) do
        nil ->
          {:error, :player_not_found}

        %Engine.PlayerHand{} = player_hand ->
          {:ok, player_hand}
      end
    else
      {:error, :game_not_found}
    end
  end

  @spec leave(game_id(), player_name()) :: {:ok, Game.t()} | :finished
  defdelegate leave(game_id, player_name), to: GameServer
end
