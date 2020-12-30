defmodule TelegramBot.User do
  @moduledoc """
  Represents a Telegram user. Usually received as `from` in telegram messages or inline queries.
  """
  defstruct [:first_name, :id, :is_bot, :language_code, :last_name, :username]

  @type t :: %__MODULE__{
          first_name: String.t(),
          id: integer(),
          is_bot: boolean(),
          language_code: String.t(),
          last_name: String.t(),
          username: String.t()
        }

  @doc """
  Build an `User` struct given a user payload.
  """
  @spec new(map()) :: t()
  def new(user_payload) do
    struct(__MODULE__, transform_to_atom_keys(user_payload))
  end

  defp transform_to_atom_keys(map) do
    Map.new(map, fn {k, v} -> {String.to_atom(k), v} end)
  end
end
