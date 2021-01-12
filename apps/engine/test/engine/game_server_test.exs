defmodule Engine.GameServerTest do
  use ExUnit.Case

  alias Engine.{Game, GameServer}

  doctest GameServer

  @game_name "test-game"

  defp start_game_server(context) do
    game = Map.get(context, :game, %Game{})

    child_spec = %{
      id: GameServer,
      start: {GameServer, :start_link, [@game_name, game]}
    }

    start_supervised!(child_spec)

    :ok
  end

  describe "join_player/2" do
    setup :start_game_server

    test "join players and define their id incrementally" do
      {:ok, _game} = GameServer.join_player(@game_name, "Felipe")
      {:ok, _game} = GameServer.join_player(@game_name, "Carlos")
      {:ok, _game} = GameServer.join_player(@game_name, "Rebeca")
      {:ok, game} = GameServer.join_player(@game_name, "Nice")

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

      assert {:error, :players_limit_reached} == GameServer.join_player(@game_name, "Renan")
    end
  end

  describe "start_game/1" do
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
      start_game_server(%{game: @game})

      {:ok, game} = GameServer.start_game(@game_name)

      assert length(game.matches) == 1
    end

    test "returns an error when there are no enough players" do
      game_missing_one_player = Map.update!(@game, :players, &List.delete_at(&1, -1))

      start_game_server(%{game: game_missing_one_player})

      assert {:error, "Game is not ready. Check if you have enough players."} ==
               GameServer.start_game(@game_name)
    end
  end

  describe "play_player_card/2" do
    setup :start_game_server

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

    @tag game: @game
    test "players are able to put their card according to the given card position" do
      {:ok, _game} = GameServer.start_game(@game_name)

      {:ok,
       %Engine.Game{
         matches: [
           %Engine.Match{
             rounds: [%Engine.Round{} = round]
           }
         ]
       }} = GameServer.play_player_card(@game_name, "Felipe", 0)

      refute round.finished?
      refute round.winner
      assert length(round.played_cards) == 1
    end

    @tag game: @game
    test "finishes the round when all players put one card" do
      {:ok, _game} = GameServer.start_game(@game_name)
      {:ok, _game} = GameServer.play_player_card(@game_name, "Felipe", 1)
      {:ok, _game} = GameServer.play_player_card(@game_name, "Carlos", 0)
      {:ok, _game} = GameServer.play_player_card(@game_name, "Rebeca", 2)

      {:ok,
       %Engine.Game{
         matches: [
           %Engine.Match{
             rounds: [%Engine.Round{} = round],
             players_hands: players_hands
           }
         ]
       }} = GameServer.play_player_card(@game_name, "Nice", 2)

      assert round.finished?
      refute is_nil(round.winner)
      assert length(round.played_cards) == 4

      for player_hand <- players_hands do
        assert length(player_hand.cards) == 2
      end
    end

    @tag game: @game
    test "change the next player once a match is finished" do
      {:ok, game} = GameServer.start_game(@game_name)

      %Game{matches: [finished_match, new_mach]} = play_until_match_is_finished(game)

      assert finished_match.finished?
      assert finished_match.starter_player_id == 1

      refute new_mach.finished?
      assert new_mach.next_player_id == 2
      assert new_mach.starter_player_id == 2
    end

    @tag game: @game
    test "finishes the game when some team reaches 12 points" do
      game =
        @game_name
        |> GameServer.start_game()
        |> play_until_game_is_finished()

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
      player_name = Map.get(@players_map, next_player_id)

      @game_name
      |> GameServer.play_player_card(player_name, card_position)
      |> play_until_game_is_finished()
    end

    defp play_until_game_is_finished({:finished, game}), do: game

    defp play_until_match_is_finished(game) do
      case game.matches do
        [current_match] ->
          card_position = 0
          player_name = Map.get(@players_map, current_match.next_player_id)
          {:ok, game} = GameServer.play_player_card(@game_name, player_name, card_position)

          play_until_match_is_finished(game)

        [_finished_match, _current_match] ->
          game
      end
    end
  end

  describe "truco/1" do
    setup :start_game_server

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

    @tag game: @game
    test "players may ask truco in their turn" do
      GameServer.start_game(@game_name)

      {:ok, game} = GameServer.truco(@game_name, "Felipe")

      assert game.blocked?

      {:ok, game} = GameServer.answer(@game_name, "Nice", :yes)

      current_match = List.last(game.matches)

      assert current_match.points == 3
      refute game.blocked?
    end

    @tag game: @game
    test "players cannot ask truco when it is not their turn" do
      GameServer.start_game(@game_name)

      assert {:error, :not_player_turn} = GameServer.truco(@game_name, "Nice")
    end

    @tag game: @game
    test "match will be finished in case a 'no' answer" do
      GameServer.start_game(@game_name)

      {:ok, game} = GameServer.truco(@game_name, "Felipe")

      assert game.blocked?

      {:ok, %Game{matches: [last_match, _new_match]}} = GameServer.answer(@game_name, "Carlos", :no)

      assert last_match.finished?
    end

    @tag game: @game
    test "players can ask for increase after a truco request" do
      GameServer.start_game(@game_name)

      {:ok, game} = GameServer.truco(@game_name, "Felipe")

      assert game.blocked?

      {:ok, game} = GameServer.answer(@game_name, "Nice", :increase)

      assert game.blocked?

      {:ok, %Game{matches: [current_match]} = game} = GameServer.answer(@game_name, "Rebeca", :yes)

      refute game.blocked?
      assert current_match.points == 6
    end

    @tag game: @game
    test "players can increase match points up to 12" do
      GameServer.start_game(@game_name)

      {:ok, game} = GameServer.truco(@game_name, "Felipe")

      assert game.blocked?

      {:ok, game} = GameServer.answer(@game_name, "Nice", :increase)

      assert game.blocked?

      {:ok, game} = GameServer.answer(@game_name, "Rebeca", :increase)

      assert game.blocked?

      {:ok, game} = GameServer.answer(@game_name, "Carlos", :increase)

      assert game.blocked?

      {:ok, %Game{matches: [current_match]} = game} = GameServer.answer(@game_name, "Felipe", :yes)

      refute game.blocked?
      assert current_match.points == 12
    end

    @tag game: @game
    test "last answer must be yes or no" do
      GameServer.start_game(@game_name)

      {:ok, game} = GameServer.truco(@game_name, "Felipe")

      assert game.blocked?

      {:ok, game} = GameServer.answer(@game_name, "Nice", :increase)

      assert game.blocked?

      {:ok, game} = GameServer.answer(@game_name, "Rebeca", :increase)

      assert game.blocked?

      {:ok, game} = GameServer.answer(@game_name, "Carlos", :increase)

      assert game.blocked?

      {:error, :points_cannot_be_increased} = GameServer.answer(@game_name, "Felipe", :increase)
    end

    @tag game: @game
    test "cannot ask truco after once match points reached 12" do
      GameServer.start_game(@game_name)

      {:ok, game} = GameServer.truco(@game_name, "Felipe")

      assert game.blocked?

      {:ok, game} = GameServer.answer(@game_name, "Nice", :increase)

      assert game.blocked?

      {:ok, game} = GameServer.answer(@game_name, "Rebeca", :increase)

      assert game.blocked?

      {:ok, game} = GameServer.answer(@game_name, "Carlos", :increase)

      assert game.blocked?

      {:ok, _game} = GameServer.answer(@game_name, "Felipe", :yes)

      {:error, :points_cannot_be_increased} = GameServer.truco(@game_name, "Felipe")
    end

    @tag game: @game
    test "players cannot answer when there is no truco" do
      GameServer.start_game(@game_name)

      assert {:error, :game_unblocked} = GameServer.answer(@game_name, "Nice", :yes)
    end

    @tag game: @game
    test "teams cannot increase points twice in row" do
      GameServer.start_game(@game_name)

      {:ok, game} = GameServer.truco(@game_name, "Felipe")

      assert game.blocked?

      {:ok, _game} = GameServer.answer(@game_name, "Nice", :yes)

      assert {:error, :not_player_turn} == GameServer.truco(@game_name, "Felipe")
    end

    @tag game: @game
    test "cannot ask truco twice" do
      GameServer.start_game(@game_name)

      {:ok, game} = GameServer.truco(@game_name, "Felipe")

      assert game.blocked?

      {:ok, game} = GameServer.answer(@game_name, "Nice", :yes)

      refute game.blocked?

      assert {:error, :not_player_turn} == GameServer.truco(@game_name, "Rebeca")
    end

    @tag game: @game
    test "does not finish the game when requesting/answering truco" do
      GameServer.start_game(@game_name)

      {:ok, _game} = GameServer.truco(@game_name, "Felipe")
      {:ok, %Game{matches: [match]}} = GameServer.answer(@game_name, "Nice", :yes)
      {:ok, _game} = GameServer.play_player_card(@game_name, "Felipe", 0)
      assert match.points == 3

      {:ok, _game} = GameServer.truco(@game_name, "Carlos")
      {:ok, %Game{matches: [match]}} = GameServer.answer(@game_name, "Rebeca", :yes)
      {:ok, _game} = GameServer.play_player_card(@game_name, "Carlos", 0)
      assert match.points == 6

      {:ok, _game} = GameServer.truco(@game_name, "Rebeca")
      {:ok, %Game{matches: [match]}} = GameServer.answer(@game_name, "Nice", :yes)
      {:ok, _game} = GameServer.play_player_card(@game_name, "Rebeca", 0)
      assert match.points == 9

      {:ok, _game} = GameServer.truco(@game_name, "Nice")
      {:ok, %Game{matches: [match]} = game} = GameServer.answer(@game_name, "Felipe", :yes)
      {:ok, _game} = GameServer.play_player_card(@game_name, "Nice", 0)
      assert match.points == 12
      refute match.finished?
      refute game.finished?

      assert {:error, :points_cannot_be_increased} == GameServer.truco(@game_name, "Felipe")
    end
  end

  describe "leave/2" do
    setup :start_game_server

    test "remove the player who requested to leave and returns new game ready for new players to join" do
      GameServer.start_game(@game_name)

      {:ok, _game} = GameServer.join_player(@game_name, "Felipe")
      {:ok, _game} = GameServer.join_player(@game_name, "Renan")

      assert {:ok,
              %Engine.Game{
                blocked?: false,
                blocked_by: nil,
                finished?: false,
                matches: [],
                players: [%Engine.Player{id: 1, name: "Felipe", team_id: 1}],
                score: %{},
                started?: false,
                winner: nil
              }} == GameServer.leave(@game_name, "Renan")
    end

    test "kills the game process if all players leave the game" do
      GameServer.start_game(@game_name)

      {:ok, _game} = GameServer.join_player(@game_name, "Felipe")
      {:ok, _game} = GameServer.join_player(@game_name, "Renan")

      {:ok, _game} = GameServer.leave(@game_name, "Felipe")

      assert :finished == GameServer.leave(@game_name, "Renan")
    end

    test "do nothing if the given player name is not present in the game" do
      GameServer.start_game(@game_name)

      {:ok, _game} = GameServer.join_player(@game_name, "Felipe")
      {:ok, game} = GameServer.join_player(@game_name, "Renan")

      assert {:ok, ^game} = GameServer.leave(@game_name, "Carlos")
    end
  end
end
