defmodule Engine.GameServer do
  use GenServer

  alias Engine.Game

  @type answers :: Game.answers()
  @type player_error :: Game.player_error()

  @doc """
  Starts a game process with the given name.

  It uses `via_tuple/1` to registry this process and its PID in the Registry.
  """
  @spec start_link(String.t(), Game.t()) :: {:ok, pid} | {:error, term()}
  def start_link(name, initial_state \\ %Game{}) do
    GenServer.start_link(__MODULE__, initial_state, name: via_tuple(name))
  end

  @doc """
  Join the given player name to the game.

  This game supports either 2, 4 or 6 players and name needs to be unique.
  """
  @spec join_player(String.t(), String.t()) ::
          {:ok, Game.t()} | {:error, :player_already_joined} | {:error, :players_limit_reached}
  def join_player(game_name, player_name) when is_binary(game_name) and is_binary(player_name) do
    game_name
    |> via_tuple()
    |> GenServer.call({:join_player, player_name})
  end

  @doc """
  Starts a game once it has enough players.
  """
  @spec start_game(String.t()) :: {:ok, Game.t()} | {:error, :game_already_started} | {:error, String.t()}
  def start_game(game_name) when is_binary(game_name) do
    game_name
    |> via_tuple()
    |> GenServer.call(:start_game)
  end

  @doc """
  Play the given card position for the the given player's name.
  """
  @spec play_player_card(String.t(), String.t(), integer()) ::
          player_error() | {:ok, Game.t()} | {:finished, Game.t()}
  def play_player_card(game_name, player_name, card_position)
      when is_binary(game_name) and is_binary(player_name) and is_integer(card_position) do
    game_name
    |> via_tuple()
    |> GenServer.call({:play_player_card, player_name, card_position})
  end

  @doc """
  Make a truco request for the given player's name.

  Players can only make a truco request in their turn. The game will be blocked and players will not
  be able to do anything else other than answer this truco request.
  """
  @spec truco(String.t(), String.t()) ::
          {:ok, Game.t()} | {:finished, Game.t()} | Game.player_error()
  def truco(game_name, player_name) when is_binary(game_name) and is_binary(player_name) do
    game_name
    |> via_tuple()
    |> GenServer.call({:truco, player_name})
  end

  @doc """
  Answer a truco request.

  This function can be called only after a Player's truco request. If that happens, Player's who
  received the truco request needs to answer:

  * yes      - this will raise the points of the match to 3.
  * no       - this will finish the match with 1 point and the team who ask truco will be the winner.
  * increase - this will ask another team to raise match points to + 3.

  In case answer `increase`, the another team will need to answer this request with one of the answers
  above. This can be a loop until the match reaches 12 points and if so, the last answer can be either
  yes or no.

  Also, a request to increase points can be done at any moment as long as points haven't reached 12
  in the same match. So, let say Team A made a truco request and Team B answered to increase + 3 (six)
  which has been accepted for Team A. Team A may ask for nine at any moment in the game in their turn.

  The Game must be blocked while waiting for an answer. It means that players cannot play any card
  until a "yes" answer happens.
  """
  @spec answer(String.t(), String.t(), answers()) ::
          {:ok, Game.t()} | {:finished, Game.t()} | Game.player_error()
  def answer(game_name, player_name, answer)
      when is_binary(game_name) and is_binary(player_name) and answer in ~w(yes no increase)a do
    game_name
    |> via_tuple()
    |> GenServer.call({:answer, player_name, answer})
  end

  @spec get(String.t()) :: Game.t() | nil
  def get(game_name) when is_binary(game_name) do
    game_name
    |> via_tuple()
    |> GenServer.call(:get)
  end

  # Uses Registry to register the game in the state.
  #
  # via tuple is a way to tell Elixir that we'll use a custom module to register our processes. In
  # this case, I'm using Registry to do this work.
  defp via_tuple(name) do
    {:via, Registry, {:game_server_registry, name}}
  end

  # --- GenServer callbacks

  @impl true
  def init(game), do: {:ok, game}

  @impl true
  def handle_call({:join_player, player_name}, _from, game) do
    case Game.add_player(game, player_name) do
      {:ok, game} ->
        {:reply, {:ok, game}, game}

      {:error, error} ->
        {:reply, {:error, error}, game}
    end
  end

  @impl true
  def handle_call(:start_game, _from, %Game{started?: true} = game), do: {:reply, {:error, :game_already_started}, game}

  @impl true
  def handle_call(:start_game, _from, %Game{started?: false} = game) do
    if Game.ready?(game) do
      game = Game.start_match(game)

      {:reply, {:ok, game}, game}
    else
      {:reply, {:error, "Game is not ready. Check if you have enough players."}, game}
    end
  end

  @impl true
  def handle_call({:play_player_card, _, _}, _from, %Game{finished?: true} = game) do
    {:reply, {:error, "this game is already finished"}, game}
  end

  @impl true
  def handle_call({:play_player_card, player_name, card_position}, _from, game) do
    case Game.play_player_card(game, player_name, card_position) do
      {:ok, game} ->
        {:reply, {:ok, game}, game}

      {:finished, game} ->
        {:reply, {:finished, game}, game}

      {:error, error} ->
        {:reply, {:error, error}, game}
    end
  end

  @impl true
  def handle_call({:truco, player_name}, _from, %Game{finished?: false} = game) do
    case Game.truco(game, player_name) do
      {:ok, game} ->
        {:reply, {:ok, game}, game}

      {:error, error} ->
        {:reply, {:error, error}, game}
    end
  end

  @impl true
  def handle_call(
        {:answer, player_name, answer},
        _,
        %Game{finished?: false, blocked?: true} = game
      ) do
    case Game.answer(game, player_name, answer) do
      {:ok, game} ->
        {:reply, {:ok, game}, game}

      {:error, error} ->
        {:reply, {:error, error}, game}
    end
  end

  @impl true
  def handle_call({:answer, _player_name, _answer}, _, game),
    do: {:reply, {:error, :game_unblocked}, game}

  @impl true
  def handle_call(:get, _, game), do: {:reply, game, game}
end
