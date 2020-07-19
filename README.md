# Truco

## GameEngine

### Structure example

```Elixir
%Engine.Game{}

# Starting a game
%Engine.Game{
  players: [
    %Engine.Player{id: 1, name: "Felipe"},
    %Engine.Player{id: 2, name: "Carlos"},
    %Engine.Player{id: 3, name: "Rebeca"},
    %Engine.Player{id: 4, name: "Nice"}
  ],
  rounds: [
    %Engine.Round{
      card_faced_up: %Engine.Card{suit: :hearts, symbol: "K"},
      deck: [],
      players_hands: [
        %Engine.PlayerHand{
          cards: [
            %Engine.Card{suit: :spades, symbol: "7"},
            %Engine.Card{suit: :diamonds, symbol: "7"}
          ],
          player: %Engine.Player{name: "Felipe", number: 1}
        },
        %Engine.PlayerHand{
          cards: [
            %Engine.Card{suit: :diamonds, symbol: "Q"},
            %Engine.Card{suit: :diamonds, symbol: "2"},
            %Engine.Card{suit: :diamonds, symbol: "6"}
          ],
          player: %Engine.Player{name: "Carlos", number: 2}
        },
        %Engine.PlayerHand{
          cards: [
            %Engine.Card{suit: :clubs, symbol: "4"},
            %Engine.Card{suit: :spades, symbol: "3"},
            %Engine.Card{suit: :hearts, symbol: "2"}
          ],
          player: %Engine.Player{name: "Rebeca", number: 3}
        },
        %Engine.PlayerHand{
          cards: [
            %Engine.Card{suit: :clubs, symbol: "6"},
            %Engine.Card{suit: :hearts, symbol: "Q"}
          ],
          player: %Engine.Player{name: "Nice", number: 3}
        }
      ],
      played_cards: [
        1 => [
          {%Engine.Player{name: "Felipe", number: 1}, %Engine.Card{suit: :diamonds, symbol: "3"}},
        ],
        2 => [],
        3 => []
      ],
      next_player: 2,
      round: 2,
      finished?: true
      points: 1,
      # will be team id.
      winner: nil
    },
  ],
  score: %{
    "felipe_rebeca" => 0,
    "carlos_nice" => 0,
  },
  finished?: false,
  winner: nil
}

# Playing first round
%Engine.Game{
  players: [
    %Engine.Player{id: 1, name: "Felipe"},
    %Engine.Player{id: 2, name: "Carlos"},
    %Engine.Player{id: 3, name: "Rebeca"},
    %Engine.Player{id: 4, name: "Nice"}
  ],
  rounds: [
    %Engine.Round{
      card_faced_up: %Engine.Card{suit: :hearts, symbol: "K"},
      deck: [],
      players_hands: [
        %Engine.PlayerHand{
          cards: [
            %Engine.Card{suit: :diamonds, symbol: "7"},
            %Engine.Card{suit: :diamonds, symbol: "3"}
          ],
          player: %Engine.Player{name: "Felipe", number: 1}
        },
        %Engine.PlayerHand{
          cards: [
            %Engine.Card{suit: :diamonds, symbol: "2"},
            %Engine.Card{suit: :diamonds, symbol: "6"}
          ],
          player: %Engine.Player{name: "Carlos", number: 2}
        },
        %Engine.PlayerHand{
          cards: [
            %Engine.Card{suit: :spades, symbol: "3"},
            %Engine.Card{suit: :hearts, symbol: "2"}
          ],
          player: %Engine.Player{name: "Rebeca", number: 3}
        },
        %Engine.PlayerHand{
          cards: [
            %Engine.Card{suit: :clubs, symbol: "6"},
            %Engine.Card{suit: :hearts, symbol: "Q"}
          ],
          player: %Engine.Player{name: "Nice", number: 3}
        }
      ],
      played_cards: [
        1 => [
          {%Engine.Player{id: 1, name: "Felipe"}, %Engine.Card{suit: :spades, symbol: "7"}},
          {%Engine.Player{id: 2, name: "Carlos"}, %Engine.Card{suit: :diamonds, symbol: "Q"}},
          {%Engine.Player{id: 3, name: "Rebeca"}, %Engine.Card{suit: :spades, symbol: "A"}},
          {%Engine.Player{id: 4, name: "Nice"}, %Engine.Card{suit: :clubs, symbol: "4"}}
        ],
        2 => [],
        3 => []
      ],
      next_player: 1,
      round: 1,
      finished?: false,
      points: 0,
      # will be team id.
      winner: nil
    }
  ],
  score: %{
    "felipe_rebeca" => 2,
    "carlos_nice" => 1,
  },
  finished?: false,
  winner: nil
}
```

### Starting a game

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
{:ok, game} = GameServer.put_player_card("Felipe", 1)
```