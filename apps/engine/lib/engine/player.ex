defmodule Engine.Player do
  @enforce_keys [:name, :number, :team_id]
  defstruct [:name, :number, :team_id]

  def new(name, number, team_id), do: %__MODULE__{name: name, number: number, team_id: team_id}
end
