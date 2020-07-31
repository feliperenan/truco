# Truco

## GameEngine

```
alias Engine.{Game, GameServer, Player, Deck}

Engine.GameServer.start_link

# join players
{:ok, game} = GameServer.join_player("Felipe")
{:ok, game} = GameServer.join_player("Carlos")
{:ok, game} = GameServer.join_player("Rebeca")
{:ok, game} = GameServer.join_player("Nice")

# start the game
{:ok, game} = GameServer.start_game()

# Play players card given the card position.
{:ok, game} = GameServer.play_player_card("Felipe", 0)
{:ok, game} = GameServer.play_player_card("Carlos", 0)
{:ok, game} = GameServer.play_player_card("Rebeca", 0)
{:ok, game} = GameServer.play_player_card("Nice", 0)

# Check rounds
length(game.rounds)
Enum.at(game.rounds, 0)

# Check points - returns %{1 => 0, 2 => 0} so that the key is the team_id and value the points.
for round <- game.rounds, round.finished?, reduce: %{} do
  acc -> Map.update(acc, round.team_winner, 0, &(&1 + round.points))
end
```
