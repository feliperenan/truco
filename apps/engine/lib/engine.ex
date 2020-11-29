defmodule Engine do
  @moduledoc """
  Documentation for `Engine`.
  """

  alias Engine.{Game, GameSupervisor, GameServer}

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

  @spec start_game(game_id()) :: {:ok, Engine.Game.t()} | {:error, String.t()}
  defdelegate start_game(game_id), to: GameServer

  @spec play_player_card(game_id(), player_name(), integer()) :: {:ok, Game.t()}
  defdelegate play_player_card(game, player_name, card_position), to: GameServer

  @spec truco(game_id(), player_name()) ::
          {:ok, Game.t()} | {:finished, Game.t()} | Game.player_error()
  defdelegate truco(game, player_name), to: GameServer

  @spec answer(game_id(), player_name(), answers()) ::
          {:ok, Game.t()} | {:finished, Game.t()} | Game.player_error()
  defdelegate answer(game, player_name, answer), to: GameServer
end
