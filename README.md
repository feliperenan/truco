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

# Player first round
{:ok, game} = GameServer.put_player_card("Felipe", 0)
{:ok, game} = GameServer.put_player_card("Carlos", 0)
{:ok, game} = GameServer.put_player_card("Rebeca", 0)
{:ok, game} = GameServer.put_player_card("Nice", 0)
```
