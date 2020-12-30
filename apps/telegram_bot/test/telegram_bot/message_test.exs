defmodule TelegramBot.MessageTest do
  use TelegramBot.DataCase

  alias TelegramBot.Chat
  alias TelegramBot.Message
  alias TelegramBot.User

  describe "new/1" do
    test "build a message struct from the webhook payload" do
      payload = %{
        "message" => %{
          "chat" => %{
            "all_members_are_administrators" => true,
            "id" => 419_752_573,
            "title" => "truco-test",
            "type" => "group"
          },
          "date" => 1_605_212_571,
          "entities" => [%{"length" => 19, "offset" => 0, "type" => "bot_command"}],
          "from" => %{
            "first_name" => "Felipe",
            "id" => 925_606_196,
            "is_bot" => false,
            "language_code" => "en",
            "last_name" => "Renan"
          },
          "message_id" => 16,
          "text" => "/start@ex_truco_bot"
        },
        "update_id" => 863_667_915
      }

      assert %Message{
               chat: %Chat{
                 all_members_are_administrators: true,
                 id: 419_752_573,
                 title: "truco-test",
                 type: "group"
               },
               date: 1_605_212_571,
               from: %User{
                 first_name: "Felipe",
                 id: 925_606_196,
                 is_bot: false,
                 language_code: "en",
                 last_name: "Renan"
               },
               message_id: 16,
               text: "/start"
             } == Message.new(payload)
    end

    test "message without text" do
      payload = %{
        "message" => %{
          "chat" => %{
            "all_members_are_administrators" => true,
            "id" => 111_111_111,
            "title" => "truco-test",
            "type" => "group"
          },
          "date" => 1_606_743_674,
          "from" => %{
            "first_name" => "Felipe",
            "id" => 222_222_222,
            "is_bot" => false,
            "language_code" => "en",
            "last_name" => "Renan"
          },
          "group_chat_created" => true,
          "message_id" => 92
        },
        "update_id" => 863_667_959
      }

      assert %Message{
               chat: %Chat{
                 all_members_are_administrators: true,
                 id: 111_111_111,
                 title: "truco-test",
                 type: "group"
               },
               date: 1_606_743_674,
               from: %User{
                 first_name: "Felipe",
                 id: 222_222_222,
                 is_bot: false,
                 language_code: "en",
                 last_name: "Renan"
               },
               message_id: 92,
               text: nil
             } == Message.new(payload)
    end
  end

  describe "build_reply/1" do
    setup [:start_game_engine, :start_game_manager]

    test "/new create a new game" do
      telegram_message = build(:message, text: "/new")

      assert %{
               text: "The game has been created and it is ready for receive players.",
               to: telegram_message.chat.id
             } == Message.build_reply(telegram_message)
    end

    test "/new does not create twice" do
      telegram_message = build(:message, text: "/new")

      Message.build_reply(telegram_message)

      text = ~s"""
      There is already a game created for this group.

      Try /join to join the game or /start to start the game.
      """

      assert %{
               text: text,
               to: telegram_message.chat.id
             } == Message.build_reply(telegram_message)
    end

    test "/join joins who sent the message to the created game" do
      :message
      |> build(text: "/new")
      |> Message.build_reply()

      telegram_message = build(:message, text: "/join")

      text =
        "You have joined the game. Now, wait for other players or send /start to start the game in case you have enough players."

      assert %{
               text: text,
               to: telegram_message.chat.id
             } == Message.build_reply(telegram_message)
    end

    test "/join returns an error in case there is no game created" do
      telegram_message = build(:message, text: "/join")

      text = "Game has not been created yet. First you need to send /new in order to create the game."

      assert %{
               text: text,
               to: telegram_message.chat.id
             } == Message.build_reply(telegram_message)
    end

    test "/join does not join the same player twice in the same game" do
      :message
      |> build(text: "/new")
      |> Message.build_reply()

      telegram_message = build(:message, text: "/join")

      Message.build_reply(telegram_message)

      assert %{
               text: "You have already joined a game.",
               to: telegram_message.chat.id
             } == Message.build_reply(telegram_message)
    end

    test "/join supports 4 players in total" do
      :message
      |> build(text: "/new")
      |> Message.build_reply()

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
        |> Message.build_reply()
      end)

      telegram_message = build(:message, text: "/join", from: build(:user, id: 555_555_555))

      assert %{
               text: "This game cannot have more players. You are now ready to start the game with /start.",
               to: telegram_message.chat.id
             } == Message.build_reply(telegram_message)
    end

    test "/start starts the game once it has enough players" do
      :message
      |> build(text: "/new")
      |> Message.build_reply()

      chat = build(:chat, type: "group")

      # join two players: user-1 and user-2.
      Enum.each(1..2, fn user_id ->
        from = build(:user, id: user_id, username: "user-#{user_id}")

        :message
        |> build(text: "/join", from: from, chat: chat)
        |> Message.build_reply()
      end)

      telegram_message =
        build(
          :message,
          text: "/start",
          chat: chat,
          from: build(:user, id: 1, username: "user-1")
        )

      reply = Message.build_reply(telegram_message)

      assert reply.text =~ "The game has been started"
      assert reply.to == telegram_message.chat.id

      # Try to start the game again to make sure game can't be started twice.
      reply = Message.build_reply(telegram_message)

      assert reply.text == "Game has been started already."
      assert reply.to == telegram_message.chat.id
    end
  end
end
