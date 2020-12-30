defmodule TelegramBot.Chat do
  @moduledoc """
  Represents a Telegram chat.
  """
  defstruct [:all_members_are_administrators, :id, :title, :type]

  @type t :: %__MODULE__{
          all_members_are_administrators: boolean(),
          id: integer(),
          title: String.t(),
          type: String.t()
        }

  @doc """
  Build an `Chat` struct given a chat payload.
  """
  @spec new(map()) :: t()
  def new(user_payload) do
    struct(__MODULE__, transform_to_atom_keys(user_payload))
  end

  defp transform_to_atom_keys(map) do
    Map.new(map, fn {k, v} -> {String.to_atom(k), v} end)
  end
end
