defmodule Engine.Player do
  @enforce_keys [:name, :number]
  defstruct [:name, :number]

  def new(name, number), do: %__MODULE__{name: name, number: number}
end
