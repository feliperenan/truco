defmodule Engine.MatchTest do
  use ExUnit.Case

  alias Engine.Card
  alias Engine.Match
  alias Engine.Player

  doctest Match

  describe "new/1" do
    test "start a new match for 2 players" do
      players = [
        %Player{name: "Felipe", id: 1, team_id: 1},
        %Player{name: "Carlos", id: 2, team_id: 1}
      ]

      %Match{
        card_faced_up: card_faced_up,
        deck: deck,
        players_hands: players_hands,
        total_players: total_players,
        rounds: rounds,
        points: points,
        next_player_id: next_player_id,
        team_winner: team_winner
      } = Match.new(players)

      assert %Card{} = card_faced_up
      assert length(deck) == 39
      assert Enum.map(players_hands, & &1.player) == players
      assert total_players == 2
      assert length(rounds) == 1
      assert next_player_id == 1
      assert points == 1
      assert is_nil(team_winner)
    end

    test "start a new match for 4 players" do
      players = [
        %Player{name: "Felipe", id: 1, team_id: 1},
        %Player{name: "Carlos", id: 2, team_id: 2},
        %Player{name: "Rebeca", id: 3, team_id: 1},
        %Player{name: "Nice", id: 4, team_id: 2}
      ]

      %Match{
        card_faced_up: card_faced_up,
        deck: deck,
        players_hands: players_hands,
        total_players: total_players,
        rounds: rounds,
        points: points,
        next_player_id: next_player_id,
        team_winner: team_winner
      } = Match.new(players)

      assert %Card{} = card_faced_up
      assert length(deck) == 39
      assert Enum.map(players_hands, & &1.player) == players
      assert total_players == 4
      assert length(rounds) == 1
      assert next_player_id == 1
      assert points == 1
      assert is_nil(team_winner)
    end

    test "does not support only 1 player" do
      players = [
        %Player{name: "Felipe", id: 1, team_id: 1}
      ]

      error_message = """
      A match does not support 1 players. The total of players must be 2 or 4.
      """

      assert_raise ArgumentError, error_message, fn ->
        Match.new(players)
      end
    end

    test "does not support 3 players" do
      players = [
        %Player{name: "Felipe", id: 1, team_id: 1},
        %Player{name: "Carlos", id: 2, team_id: 2},
        %Player{name: "Rebeca", id: 3, team_id: 1}
      ]

      error_message = """
      A match does not support 3 players. The total of players must be 2 or 4.
      """

      assert_raise ArgumentError, error_message, fn ->
        Match.new(players)
      end
    end
  end
end
