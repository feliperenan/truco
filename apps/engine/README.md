# Engine

This is the core of the game. Here you will find the rules and server implementation.

## Basic flow

```
alias Engine.{Game, GameServer, Player, Deck}

# Starts a game server
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

# Check matches
length(game.matches)
Enum.at(game.matches, 0)

# Check points - returns %{1 => 0, 2 => 0} so that the key is the team_id and value the points.
for round <- game.matches, round.finished?, reduce: %{} do
  acc -> Map.update(acc, round.team_winner, 0, &(&1 + round.points))
end
```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `engine` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:engine, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/engine](https://hexdocs.pm/engine).
