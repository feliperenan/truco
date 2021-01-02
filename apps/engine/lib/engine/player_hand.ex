defmodule Engine.PlayerHand do
  @enforce_keys [:player, :cards]
  defstruct [:player, :cards]

  alias Engine.{Card, Player}

  @type t() :: %__MODULE__{player: Player.t(), cards: list(Card.t())}

  def new(player, cards), do: %__MODULE__{player: player, cards: cards}
end
