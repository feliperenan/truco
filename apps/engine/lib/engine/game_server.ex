defmodule Engine.GameServer do
  use GenServer

  @doc """
  TODO: add docs.
  """
  def start_link do
    GenServer.start_link(__MODULE__, %Engine.Game{}, name: __MODULE__)
  end

  @doc """
  TODO: add docs.
  """
  def join_player(player_name) do
    GenServer.call(__MODULE__, {:join_player, player_name})
  end

  @doc """
  TODO: add docs.
  """
  def start_game do
    GenServer.call(__MODULE__, :start_game)
  end

  @doc """
  TODO: add docs.
  """
  def play_player_card(player_name, card_position) do
    GenServer.call(__MODULE__, {:play_player_card, player_name, card_position})
  end

  # --- GenServer callbacks

  @impl true
  def init(game), do: {:ok, game}

  @impl true
  def handle_call({:join_player, player_name}, _from, game) do
    case Engine.Game.add_player(game, player_name) do
      {:ok, game} ->
        {:reply, {:ok, game}, game}

      {:error, error} ->
        {:reply, {:error, error}, game}
    end
  end

  @impl true
  def handle_call(:start_game, _from, game) do
    if Engine.Game.ready?(game) do
      game = Engine.Game.start_round(game)

      {:reply, {:ok, game}, game}
    else
      {:reply, {:error, "Game is not ready. Check if you have enough players."}, game}
    end
  end

  @impl true
  def handle_call({:play_player_card, _, _}, _from, %Engine.Game{finished?: true} = game) do
    {:reply, {:error, "this game is already finished"}, game}
  end

  @impl true
  def handle_call({:play_player_card, player_name, card_position}, _from, game) do
    case Engine.Game.play_player_card(game, player_name, card_position) do
      {:ok, game} ->
        {:reply, {:ok, game}, game}

      {:error, error} ->
        {:reply, {:error, error}, game}
    end
  end
end
