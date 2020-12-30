defmodule TelegramBot.MessageTest do
  use ExUnit.Case

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
               chat: %{
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
               chat: %{
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
end
