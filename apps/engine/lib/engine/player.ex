defmodule Engine.Player do
  @enforce_keys [:name, :id, :team_id]
  defstruct [:name, :id, :team_id]

  @type t :: %__MODULE__{
          name: String.t(),
          id: integer(),
          team_id: integer()
        }

  @spec new(String.t(), integer(), integer()) :: t()
  def new(name, id, team_id), do: %__MODULE__{name: name, id: id, team_id: team_id}
end
