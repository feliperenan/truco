defmodule Engine.GameServerTest do
  use ExUnit.Case

  alias Engine.GameServer

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
               score: nil,
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

      {:error, "Game is not ready. Check if you have enough players."} = GameServer.start_game()
    end
  end
end
