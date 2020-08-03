defmodule Engine.CardTest do
  use ExUnit.Case

  alias Engine.Card

  doctest Card

  describe "set_special/2" do
    for {symbol, position} <- Card.symbols() |> Enum.with_index() do
      @symbol symbol
      @position position
      @previous_symbol Enum.at(Card.symbols(), @position - 1)

      test "#{@symbol} is special when #{@previous_symbol} is faced up" do
        faced_up =
          Card.suits()
          |> Enum.random()
          |> Card.new(@previous_symbol)

        card =
          Card.suits()
          |> Enum.random()
          |> Card.new(@symbol)
          |> Card.set_special(faced_up)

        assert card.special == true
        assert card.strength > 9
      end
    end

    test "4 must be special when 3 is faced up" do
      faced_up = Card.new(:spades, "3")

      diamonds = Card.new(:diamonds, "4")
      spades = Card.new(:spades, "4")
      hearts = Card.new(:hearts, "4")
      clubs = Card.new(:clubs, "4")

      assert %Card{special: true, strength: 10} = Card.set_special(diamonds, faced_up)
      assert %Card{special: true, strength: 11} = Card.set_special(spades, faced_up)
      assert %Card{special: true, strength: 12} = Card.set_special(hearts, faced_up)
      assert %Card{special: true, strength: 13} = Card.set_special(clubs, faced_up)
    end

    test "is not special when the given card is not one" do
      card = Card.new(:diamonds, "3")
      faced_up = Card.new(:spades, "4")

      assert %Card{special: false} = Card.set_special(card, faced_up)
    end
  end
end
