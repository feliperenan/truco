defmodule Engine.PlayerHand do
  @enforce_keys [:player, :cards]
  defstruct [:player, :cards]

  def new(player, cards), do: %__MODULE__{player: player, cards: cards}
end
