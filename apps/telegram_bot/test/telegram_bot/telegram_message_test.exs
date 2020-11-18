defmodule TelegramBot.TelegramMessageTest do
  use ExUnit.Case

  alias TelegramBot.TelegramMessage

  describe "new/1" do
    test "build a message struct from the webhook payload" do
      payload = %{
        "message" => %{
          "chat" => %{
            "all_members_are_administrators" => true,
            "id" => -419_752_573,
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

      assert %TelegramMessage{
               chat: %{
                 all_members_are_administrators: true,
                 id: -419_752_573,
                 title: "truco-test",
                 type: "group"
               },
               date: 1_605_212_571,
               from: %{
                 first_name: "Felipe",
                 id: 925_606_196,
                 is_bot: false,
                 language_code: "en",
                 last_name: "Renan"
               },
               id: nil,
               text: "/start"
             } == TelegramMessage.new(payload)
    end
  end
end
