defmodule Engine.Player do
  @enforce_keys [:name, :id, :team_id]
  defstruct [:name, :id, :team_id]

  def new(name, id, team_id), do: %__MODULE__{name: name, id: id, team_id: team_id}
end
