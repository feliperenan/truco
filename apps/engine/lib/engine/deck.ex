defmodule Engine.Deck do
  @moduledoc """
  The deck is composed by 40 cards so that each suit (Spades, Hearts, Diamonds and Clubs) has 10
  cards from strongest to weakest: 3, 2, A, 4, 5, 6, 7, Q, J, K.
  """
  @enforce_keys [:cards]
  defstruct [:cards]

  alias Engine.Card

  @type t :: %__MODULE__{cards: list(Card.t())}

  cards =
    for suit <- ~w(diamonds spades hearts clubs)a do
      for symbol <- ~w(3 2 A 4 5 6 7 Q J K) do
        Card.new(suit, symbol)
      end
    end

  @cards List.flatten(cards)

  @doc """
  Returns a shuffled deck.
  """
  @spec new() :: list(Card.t())
  def new, do: Enum.shuffle(@cards)

  @doc """
  Returns a unshuffled deck.
  """
  @spec fixed() :: list(Card.t())
  def fixed, do: @cards
end
