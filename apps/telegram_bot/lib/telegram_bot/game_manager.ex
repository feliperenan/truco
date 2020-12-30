defmodule TelegramBot.GameManager do
  @moduledoc """
  Responsible for storing created games and users that are playing it under an OTP process.

  The game is going to be stored in the following format:

     %{"game_id" => ["user_id", ...], ...}

  So that the `game_id` is the key and its value is a list with ids of users present on the game.

  For now, a User cannot be in multiple games. That is because I could not find a good way to retrieve the `game_id` which
  comes from the `chat` which it's not present when a inline query is sent: https://core.telegram.org/bots/api#inlinequery.

  Therefore, once this bot receive a inline query (which happens when the bot sends cards to the user), since I don't have
  any information from each chat the inline query is coming from, the `game_id` will be fetch from this module from the
  `user_id`.
  """
  use Agent

  @type chat :: %{id: integer(), title: String.t()}

  def start_link(initial_value \\ %{}) do
    Agent.start_link(fn -> initial_value end, name: __MODULE__)
  end

  @doc """
  Put a new game in the state and returns the `game_id`. Returns the `game_id` in case the game has been created already.

  ### Examples

      iex> GameManager.new_game(%{id: 1, title: "my-group"})
      "my-group-1"
  """
  @spec new_game(chat()) :: String.t()
  def new_game(chat) do
    game_id = Integer.to_string(chat.id)

    Agent.get_and_update(__MODULE__, fn state ->
      {game_id, Map.put_new(state, game_id, [])}
    end)
  end

  @doc """
  Adds the given `user_id` to a previously created game. In case there is no such game, it will be created with this
  user.

  ### Examples

      iex> GameManager.add_user(%{id: 1, title: "my-group"}, 19386910)
      {:ok, "my-group-1"}
  """
  @spec add_user(chat(), integer()) :: {:ok, String.t(), {:error, :duplicated_join}}
  def add_user(chat, user_id) do
    game_id = Integer.to_string(chat.id)

    Agent.get_and_update(__MODULE__, fn state ->
      if user_in_some_game?(state, user_id) do
        {{:error, :duplicated_join}, state}
      else
        new_state = Map.update(state, game_id, [user_id], &[user_id | &1])
        {{:ok, game_id}, new_state}
      end
    end)
  end

  defp user_in_some_game?(state, user_id) do
    Enum.any?(state, fn {_game_id, user_ids} -> user_id in user_ids end)
  end

  @doc """
  Get the `game_id` according to the given `user_id`.

  ### Examples

      iex> GameManager.get_game_id(user_id: 19386910)
      {:ok, "my-group-1"}
  """
  @spec get_game_id(user_id: integer()) :: {:ok, String.t()} | {:error, :game_not_found}
  def get_game_id(user_id: user_id) do
    Agent.get(__MODULE__, fn state ->
      case Enum.find(state, fn {_game_id, user_ids} -> user_id in user_ids end) do
        nil ->
          {:error, :game_not_found}

        {game_id, _user_ids} ->
          {:ok, game_id}
      end
    end)
  end
end
