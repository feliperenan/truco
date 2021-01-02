defmodule Engine.Card do
  @enforce_keys [:suit, :symbol]
  defstruct suit: nil, symbol: nil, special: false, strength: 0

  @type t() :: %__MODULE__{suit: atom(), symbol: String.t()}

  @suits ~w(diamonds spades hearts clubs)a
  @symbols ~w(4 5 6 7 Q J K A 2 3)
  @symbols_with_index Enum.with_index(@symbols)

  @doc """
  Returns available symbols from weakest to strongest according to Truco rules.
  """
  def symbols, do: @symbols

  @doc """
  Returns valid suits for a card.
  """
  def suits, do: @suits

  @doc """
  Creates a card according to the given suit and symbol once they are valid.

  ### Examples

      iex> Card.new(:hearts, "3")
      %Card{suit: :hearts, symbol: "3", strength: 9}

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

  @doc """
  Set the card special when the given card is one symbol higher than the faced up card. Usually,
  we call this card as "manilha". This also change the card strength according to its suit:

  * diamonds - 10
  * spades   - 11
  * hears    - 12
  * clubs    - 13

  ### Examples

      iex> faced_up = Card.new(:spades, "7")
      iex> :clubs |> Card.new("Q") |> Card.set_special(faced_up)
      %Card{symbol: "Q", suit: :clubs, special: true, strength: 13}

      iex> faced_up = Card.new(:clubs, "K")
      iex> :hearts |> Card.new("A") |> Card.set_special(faced_up)
      %Card{symbol: "A", suit: :hearts, special: true, strength: 12}

  """
  def set_special(%__MODULE__{} = card, faced_up) do
    {_sym, card_pos} = get_card_position(card)

    # Because I'm relying on the symbol positions in the @symbols_with_index list, I need to return
    # -1 when it is the last position since first symbol (4) will be special when last symbol (3)
    # is faced up.
    faced_up_pos =
      case get_card_position(faced_up) do
        {_sym, 9} -> -1
        {_sym, faced_up_pos} -> faced_up_pos
      end

    if card_pos - 1 == faced_up_pos do
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
