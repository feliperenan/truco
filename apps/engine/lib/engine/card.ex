defmodule Engine.Card do
  @enforce_keys [:suit, :symbol]
  defstruct suit: nil, symbol: nil, special: false, strength: 0

  @suits ~w(diamonds spades hearts clubs)a
  @symbols ~w(4 5 6 7 Q J K A 2 3)
  @symbols_with_index Enum.with_index(@symbols)

  @doc """
  Creates a card according to the given suit and symbol once they are valid.

  ### Examples

      iex> Card.new(:hearts, "3")
      %Card{suit: :hearts, symbol: "3"}

  """
  def new(suit, symbol) when suit in @suits and symbol in @symbols do
    {_sym, pos} = Enum.find(@symbols_with_index, fn {sym, _pos} -> sym == symbol end)

    %__MODULE__{suit: suit, symbol: symbol, special: false, strength: pos}
  end

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

  def gt?(card_a, card_b), do: card_a.strength > card_b.strength

  @doc """
  Compare two cards and returns :eq, :lt or :gt according to their strength.
  """
  def compare(%__MODULE__{strength: a}, %__MODULE__{strength: b}) do
    cond do
      a == b ->
        :eq

      a < b ->
        :lt

      a > b ->
        :gt
    end
  end

  def set_special(%__MODULE__{} = card, faced_up) do
    {_sym, card_pos} = get_card_position(card)
    {_sym, faced_up_pos} = get_card_position(faced_up)

    if card_pos + 1 == faced_up_pos do
      %{card | special: true, strength: set_strength(card.suit)}
    else
      card
    end
  end

  defp get_card_position(%__MODULE__{symbol: symbol}),
    do: Enum.find(@symbols_with_index, fn {sym, _pos} -> sym == symbol end)

  def set_strength(:diamonds), do: 10
  def set_strength(:spades), do: 11
  def set_strength(:hearts), do: 12
  def set_strength(:clubs), do: 13
end
