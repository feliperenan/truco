defmodule TelegramBot.MessageHandlerTest do
  use ExUnit.Case

  alias TelegramBot.MessageHandler

  import TelegramBot.Factory

  def start_game_engine(_context) do
    start_supervised!(%{
      id: Engine.Application,
      start: {Engine.Application, :start, [nil, nil]}
    })

    :ok
  end

  describe "process_message/1" do
    setup :start_game_engine

    test "/new create a new game" do
      telegram_message = build(:telegram_message, text: "/new")

      assert %{
               text: "The game has been created and it is ready for receive players.",
               to: telegram_message.chat.id
             } == MessageHandler.process_message(telegram_message)
    end

    test "/new does not start game on private conversation" do
      telegram_message =
        build(:telegram_message,
          text: "/new",
          chat: build(:telegram_message_chat, type: "private")
        )

      text = ~s"""
      I can't start a game from a private conversation.

      In order to play the game, you need to create a group with people you want to play.
      """

      assert %{
               text: text,
               to: telegram_message.chat.id
             } == MessageHandler.process_message(telegram_message)
    end

    test "/new does not create twice" do
      telegram_message = build(:telegram_message, text: "/new")

      MessageHandler.process_message(telegram_message)

      text = ~s"""
      There is already a game created for this group.

      Try /join to join the game or /start to start the game.
      """

      assert %{
               text: text,
               to: telegram_message.chat.id
             } == MessageHandler.process_message(telegram_message)
    end

    test "/join joins who sent the message to the created game" do
      :telegram_message
      |> build(text: "/new")
      |> MessageHandler.process_message()

      telegram_message = build(:telegram_message, text: "/join")

      text =
        "You have joined the game. Now, wait for other players or send /start to start the game in case you have enough players."

      assert %{
               text: text,
               to: telegram_message.chat.id
             } == MessageHandler.process_message(telegram_message)
    end

    test "/join returns an error in case there is no game created" do
      telegram_message = build(:telegram_message, text: "/join")

      text = "Game has not been created yet. First you need to send /new in order to create the game."

      assert %{
               text: text,
               to: telegram_message.chat.id
             } == MessageHandler.process_message(telegram_message)
    end

    test "/join does not join the same player twice in the same game" do
      :telegram_message
      |> build(text: "/new")
      |> MessageHandler.process_message()

      telegram_message = build(:telegram_message, text: "/join")

      MessageHandler.process_message(telegram_message)

      assert %{
               text: "You have already joined the game. Now, wait for other players to join.",
               to: telegram_message.chat.id
             } == MessageHandler.process_message(telegram_message)
    end

    test "/join supports 4 players in total" do
      :telegram_message
      |> build(text: "/new")
      |> MessageHandler.process_message()

      chat = build(:telegram_message_chat, type: "group")

      [
        111_111_111,
        222_222_222,
        333_333_333,
        444_444_444
      ]
      |> Enum.each(fn user_id ->
        from = build(:telegram_message_from, id: user_id)

        :telegram_message
        |> build(text: "/join", from: from, chat: chat)
        |> MessageHandler.process_message()
      end)

      telegram_message =
        build(:telegram_message, text: "/join", from: build(:telegram_message_from, %{id: 555_555_555}))

      assert %{
               text: "This game cannot have more players. You are now ready to start the game with /start.",
               to: telegram_message.chat.id
             } == MessageHandler.process_message(telegram_message)
    end
  end
end
