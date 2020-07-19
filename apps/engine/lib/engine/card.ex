defmodule Engine.Card do
  @enforce_keys [:suit, :symbol]
  defstruct [:suit, :symbol]

  @suits ~w(♠️ ♥ ♦️ ♣️)a
  @symbols ~w(3 2 A 4 5 6 7 Q J K)

  @doc """
  Creates a card according to the given suit and symbol once they are valid.

  ### Examples

      iex> Card.new(:hearts, "3")
      %Card{suit: :hearts, symbol: "3"}

  """
  def new(suit, symbol) when suit in @suits and symbol in @symbols,
    do: %__MODULE__{suit: suit, symbol: symbol}

  @doc """
  Check if the given cards are the same lookin at they suit and symbol.

  ### Examples

      iex> card_a = Card.new(:spades, "3")
      iex> card_b = Card.new(:spades, "3")
      iex> Card.eq?(card_a, card_b)
      iex> true

      iex> card_a = Card.new(:spades, "A")
      iex> card_b = Card.new(:spades, "3")
      iex> Card.eq?(card_a, card_b)
      iex> false

  """
  def eq?(%__MODULE__{symbol: symbol, suit: suit}, %__MODULE__{symbol: symbol, suit: suit}),
    do: true

  def eq?(_card_a, _card_b), do: false
end
