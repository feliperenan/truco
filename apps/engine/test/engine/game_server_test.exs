defmodule Engine.GameServerTest do
  use ExUnit.Case

  alias Engine.{Game, GameServer}

  doctest GameServer

  describe "join_player/2" do
    test "join players and define their id incrementally" do
      start_supervised!(GameServer)

      {:ok, _game} = GameServer.join_player("Felipe")
      {:ok, _game} = GameServer.join_player("Carlos")
      {:ok, _game} = GameServer.join_player("Rebeca")
      {:ok, game} = GameServer.join_player("Nice")

      assert game == %Engine.Game{
               finished?: false,
               matches: [],
               players: [
                 %Engine.Player{id: 1, name: "Felipe", team_id: 1},
                 %Engine.Player{id: 2, name: "Carlos", team_id: 2},
                 %Engine.Player{id: 3, name: "Rebeca", team_id: 1},
                 %Engine.Player{id: 4, name: "Nice", team_id: 2}
               ],
               score: %{},
               winner: nil
             }

      assert {:error, "This game has already 4 players."} == GameServer.join_player("Renan")
    end
  end

  describe "start_game/0" do
    @game %Engine.Game{
      finished?: false,
      matches: [],
      players: [
        %Engine.Player{id: 1, name: "Felipe", team_id: 1},
        %Engine.Player{id: 2, name: "Carlos", team_id: 2},
        %Engine.Player{id: 3, name: "Rebeca", team_id: 1},
        %Engine.Player{id: 4, name: "Nice", team_id: 2}
      ],
      score: nil,
      winner: nil
    }

    test "starts the game when there are enough players" do
      child_spec = %{
        id: GameServer,
        start: {GameServer, :start_link, [nil, @game]}
      }

      start_supervised!(child_spec)

      {:ok, game} = GameServer.start_game()

      assert length(game.matches) == 1
    end

    test "returns an error when there are no enough players" do
      game_missing_one_player = Map.update!(@game, :players, &List.delete_at(&1, -1))

      child_spec = %{
        id: GameServer,
        start: {GameServer, :start_link, [nil, game_missing_one_player]}
      }

      start_supervised!(child_spec)

      assert {:error, "Game is not ready. Check if you have enough players."} ==
               GameServer.start_game()
    end
  end

  describe "play_player_card/2" do
    @game %Engine.Game{
      finished?: false,
      matches: [],
      players: [
        %Engine.Player{id: 1, name: "Felipe", team_id: 1},
        %Engine.Player{id: 2, name: "Carlos", team_id: 2},
        %Engine.Player{id: 3, name: "Rebeca", team_id: 1},
        %Engine.Player{id: 4, name: "Nice", team_id: 2}
      ]
    }

    test "players are able to put their card according to the given card position" do
      child_spec = %{
        id: GameServer,
        start: {GameServer, :start_link, [nil, @game]}
      }

      start_supervised!(child_spec)

      {:ok, _game} = GameServer.start_game()

      {:ok,
       %Engine.Game{
         matches: [
           %Engine.Match{
             rounds: [%Engine.Round{} = round]
           }
         ]
       }} = GameServer.play_player_card("Felipe", 0)

      refute round.finished?
      refute round.winner
      assert length(round.played_cards) == 1
    end

    test "finishes the round when all players put one card" do
      child_spec = %{
        id: GameServer,
        start: {GameServer, :start_link, [nil, @game]}
      }

      start_supervised!(child_spec)

      {:ok, _game} = GameServer.start_game()
      {:ok, _game} = GameServer.play_player_card("Felipe", 1)
      {:ok, _game} = GameServer.play_player_card("Carlos", 0)
      {:ok, _game} = GameServer.play_player_card("Rebeca", 2)

      {:ok,
       %Engine.Game{
         matches: [
           %Engine.Match{
             rounds: [%Engine.Round{} = round],
             players_hands: players_hands
           }
         ]
       }} = GameServer.play_player_card("Nice", 2)

      assert round.finished?
      refute is_nil(round.winner)
      assert length(round.played_cards) == 4

      for player_hand <- players_hands do
        assert length(player_hand.cards) == 2
      end
    end

    test "finishes the game when some team reaches 12 points" do
      child_spec = %{
        id: GameServer,
        start: {GameServer, :start_link, [nil, @game]}
      }

      start_supervised!(child_spec)

      game = GameServer.start_game() |> play_until_game_is_finished()

      assert game.finished?
      assert game.score |> Map.values() |> Enum.any?(&(&1 >= 12))
    end

    @players_map %{
      1 => "Felipe",
      2 => "Carlos",
      3 => "Rebeca",
      4 => "Nice"
    }

    defp play_until_game_is_finished({:ok, game}) do
      %{next_player_id: next_player_id} = List.last(game.matches)
      card_position = 0

      @players_map
      |> Map.get(next_player_id)
      |> GameServer.play_player_card(card_position)
      |> play_until_game_is_finished()
    end

    defp play_until_game_is_finished({:finished, game}), do: game
  end

  describe "truco/1" do
    @game %Engine.Game{
      finished?: false,
      matches: [],
      players: [
        %Engine.Player{id: 1, name: "Felipe", team_id: 1},
        %Engine.Player{id: 2, name: "Carlos", team_id: 2},
        %Engine.Player{id: 3, name: "Rebeca", team_id: 1},
        %Engine.Player{id: 4, name: "Nice", team_id: 2}
      ]
    }

    test "players may ask truco in their turn" do
      child_spec = %{
        id: GameServer,
        start: {GameServer, :start_link, [nil, @game]}
      }

      start_supervised!(child_spec)

      GameServer.start_game()

      {:ok, game} = GameServer.truco("Felipe")

      assert game.blocked?

      {:ok, game} = GameServer.answer("Nice", "yes")

      current_match = List.last(game.matches)

      assert current_match.points == 3
      refute game.blocked?
    end

    test "players cannot ask truco when it is not their turn" do
      child_spec = %{
        id: GameServer,
        start: {GameServer, :start_link, [nil, @game]}
      }

      start_supervised!(child_spec)

      GameServer.start_game()

      assert {:error, :not_player_turn} = GameServer.truco("Nice")
    end

    test "match will be finished in case a 'no' answer" do
      child_spec = %{
        id: GameServer,
        start: {GameServer, :start_link, [nil, @game]}
      }

      start_supervised!(child_spec)

      GameServer.start_game()

      {:ok, game} = GameServer.truco("Felipe")

      assert game.blocked?

      {:ok, %Game{matches: [last_match, _new_match]}} = GameServer.answer("Carlos", "no")

      assert last_match.finished?
    end

    test "players can ask for increase after a truco request" do
      child_spec = %{
        id: GameServer,
        start: {GameServer, :start_link, [nil, @game]}
      }

      start_supervised!(child_spec)

      GameServer.start_game()

      {:ok, game} = GameServer.truco("Felipe")

      assert game.blocked?

      {:ok, game} = GameServer.answer("Nice", "increase")

      assert game.blocked?

      {:ok, %Game{matches: [current_match]} = game} = GameServer.answer("Rebeca", "yes")

      refute game.blocked?
      assert current_match.points == 6
    end

    test "players can increase match points up to 12" do
      child_spec = %{
        id: GameServer,
        start: {GameServer, :start_link, [nil, @game]}
      }

      start_supervised!(child_spec)

      GameServer.start_game()

      {:ok, game} = GameServer.truco("Felipe")

      assert game.blocked?

      {:ok, game} = GameServer.answer("Nice", "increase")

      assert game.blocked?

      {:ok, game} = GameServer.answer("Rebeca", "increase")

      assert game.blocked?

      {:ok, game} = GameServer.answer("Carlos", "increase")

      assert game.blocked?

      {:ok, %Game{matches: [current_match]} = game} = GameServer.answer("Felipe", "yes")

      refute game.blocked?
      assert current_match.points == 12
    end

    test "last answer must be yes or no" do
      child_spec = %{
        id: GameServer,
        start: {GameServer, :start_link, [nil, @game]}
      }

      start_supervised!(child_spec)

      GameServer.start_game()

      {:ok, game} = GameServer.truco("Felipe")

      assert game.blocked?

      {:ok, game} = GameServer.answer("Nice", "increase")

      assert game.blocked?

      {:ok, game} = GameServer.answer("Rebeca", "increase")

      assert game.blocked?

      {:ok, game} = GameServer.answer("Carlos", "increase")

      assert game.blocked?

      {:error, :points_cannot_be_increased} = GameServer.answer("Felipe", "increase")
    end

    test "cannot ask truco after once match points reached 12" do
      child_spec = %{
        id: GameServer,
        start: {GameServer, :start_link, [nil, @game]}
      }

      start_supervised!(child_spec)

      GameServer.start_game()

      {:ok, game} = GameServer.truco("Felipe")

      assert game.blocked?

      {:ok, game} = GameServer.answer("Nice", "increase")

      assert game.blocked?

      {:ok, game} = GameServer.answer("Rebeca", "increase")

      assert game.blocked?

      {:ok, game} = GameServer.answer("Carlos", "increase")

      assert game.blocked?

      {:ok, _game} = GameServer.answer("Felipe", "yes")

      {:error, :points_cannot_be_increased} = GameServer.truco("Felipe")
    end

    test "players cannot answer when there is no truco" do
      child_spec = %{
        id: GameServer,
        start: {GameServer, :start_link, [nil, @game]}
      }

      start_supervised!(child_spec)

      GameServer.start_game()

      assert {:error, :game_unblocked} = GameServer.answer("Nice", "yes")
    end

    test "teams cannot increase points twice in row" do
      child_spec = %{
        id: GameServer,
        start: {GameServer, :start_link, [nil, @game]}
      }

      start_supervised!(child_spec)

      GameServer.start_game()

      {:ok, game} = GameServer.truco("Felipe")

      assert game.blocked?

      {:ok, _game} = GameServer.answer("Nice", "yes")

      {:error, :not_player_team_turn} = GameServer.truco("Felipe")
    end
  end
end
