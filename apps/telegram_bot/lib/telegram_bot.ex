defmodule TelegramBot do
  alias TelegramBot.TelegramMessage
  alias TelegramBot.MessageHandler

  require Logger

  @doc """
  Process the given command received from Telegram webhook and reply it properly..

  ### Commands

  - /new      - it will create a new game in the chat group.
  - /join     - it will join the sender to the created game.
  - /start    - it will start a the game as long as it has enough players.
  - /my_cards - replies a keyoboard to who requested to his cards.

  ### Gameplay example

  Imagine there is a group created with: @ex-truco-bot, @felipe and @renan and below commands is
  executed inside a telegram app.

  felipe>
    /new

  ex-truco-bot>
    The game has been created and it is ready for receive players.

  felipe>
  /join

  ex-truco-bot>
    You have joined the game. Now, wait for other players or send /start to start the game in case
    you have enough players.

  renan>
    /join

  ex-truco-bot>
    You have joined the game. Now, wait for other players or send /start to start the game in case
    you have enough players.

  felipe>
    /start

  ex-truco-bot>
    The game has been started

    The card faced up is: 3 ♠️
    The player who starts is: @felipe

    To check your cards, send /my_cards

  felipe>
    /my_cards

  ex-truco-bot>
    You must be able to see your cards on your keyboard @felipe
  """
  @spec process_message(map()) :: :ok
  def process_message(message_payload) do
    reply =
      message_payload
      |> TelegramMessage.new()
      |> MessageHandler.process_message()

    reply_markup = Map.get(reply, :reply_markup, %{})

    {:ok, _message} =
      Nadia.send_message(
        reply.to,
        reply.text,
        reply_markup: reply_markup,
        reply_to_message_id: reply[:message_id]
      )

    :ok
  end
end
