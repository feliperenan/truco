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
end
