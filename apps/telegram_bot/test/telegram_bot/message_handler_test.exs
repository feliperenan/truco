defmodule TelegramBot.MessageHandlerTest do
  use ExUnit.Case

  alias TelegramBot.MessageHandler

  import TelegramBot.Factory

  def start_game_engine(_context) do
    start_supervised!(%{
      id: Engine.Application,
      start: {Engine.Application, :start, [nil, nil]}
    })

    start_supervised!({TelegramBot.GameManager, %{}})

    :ok
  end

  describe "process_message/1" do
    setup :start_game_engine

    test "/new create a new game" do
      telegram_message = build(:message, text: "/new")

      assert %{
               text: "The game has been created and it is ready for receive players.",
               to: telegram_message.chat.id
             } == MessageHandler.process_message(telegram_message)
    end

    test "/new does not create twice" do
      telegram_message = build(:message, text: "/new")

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
      :message
      |> build(text: "/new")
      |> MessageHandler.process_message()

      telegram_message = build(:message, text: "/join")

      text =
        "You have joined the game. Now, wait for other players or send /start to start the game in case you have enough players."

      assert %{
               text: text,
               to: telegram_message.chat.id
             } == MessageHandler.process_message(telegram_message)
    end

    test "/join returns an error in case there is no game created" do
      telegram_message = build(:message, text: "/join")

      text = "Game has not been created yet. First you need to send /new in order to create the game."

      assert %{
               text: text,
               to: telegram_message.chat.id
             } == MessageHandler.process_message(telegram_message)
    end

    test "/join does not join the same player twice in the same game" do
      :message
      |> build(text: "/new")
      |> MessageHandler.process_message()

      telegram_message = build(:message, text: "/join")

      MessageHandler.process_message(telegram_message)

      assert %{
               text: "You have already joined a game.",
               to: telegram_message.chat.id
             } == MessageHandler.process_message(telegram_message)
    end

    test "/join supports 4 players in total" do
      :message
      |> build(text: "/new")
      |> MessageHandler.process_message()

      chat = build(:chat, type: "group")

      [
        111_111_111,
        222_222_222,
        333_333_333,
        444_444_444
      ]
      |> Enum.each(fn user_id ->
        from = build(:user, id: user_id, username: "#{user_id}")

        :message
        |> build(text: "/join", from: from, chat: chat)
        |> MessageHandler.process_message()
      end)

      telegram_message =
        build(:message, text: "/join", from: build(:user, id: 555_555_555))

      assert %{
               text: "This game cannot have more players. You are now ready to start the game with /start.",
               to: telegram_message.chat.id
             } == MessageHandler.process_message(telegram_message)
    end

    test "/start starts the game once it has enough players" do
      :message
      |> build(text: "/new")
      |> MessageHandler.process_message()

      chat = build(:chat, type: "group")

      # join two players: user-1 and user-2.
      Enum.each(1..2, fn user_id ->
        from = build(:user, id: user_id, username: "user-#{user_id}")

        :message
        |> build(text: "/join", from: from, chat: chat)
        |> MessageHandler.process_message()
      end)

      telegram_message =
        build(
          :message,
          text: "/start",
          chat: chat,
          from: build(:user, id: 1, username: "user-1")
        )

      reply = MessageHandler.process_message(telegram_message)

      assert reply.text =~ "The game has been started"
      assert reply.to == telegram_message.chat.id

      # Try to start the game again to make sure game can't be started twice.
      reply = MessageHandler.process_message(telegram_message)

      assert reply.text == "Game has been started already."
      assert reply.to == telegram_message.chat.id
    end
  end
end
