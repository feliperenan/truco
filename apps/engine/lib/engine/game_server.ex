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
  def put_player_card(player_name, card_position) do
    GenServer.call(__MODULE__, {:put_player_card, player_name, card_position})
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
  def handle_call({:put_player_card, _, _}, _from, %Engine.Game{finished?: true} = game) do
    {:reply, {:error, "this game is already finished"}, game}
  end

  @impl true
  def handle_call({:put_player_card, player_name, card_position}, _from, game) do
    case Engine.Game.put_player_card(game, player_name, card_position) do
      {:ok, game} ->
        # TODO:
        # check if someone finished this round and,
        #  * if so:
        #   * check who won the round.
        #   * increase points for the round winner
        #   * check if the player has won the game
        #   * start another round if there is no winner
        #  if doesn't:
        #   * set next player according to his/her number.
        {:reply, {:ok, game}, game}

      {:error, error} ->
        {:reply, {:error, error}, game}
    end
  end
end
