defmodule TelegramBot.Integrations.WebhookTest do
  use ExUnit.Case, async: true
  use Plug.Test

  @opts TelegramBot.Endpoint.init([])

  setup do
    bypass = Bypass.open()

    Application.put_env(:nadia, :base_url, "http://localhost:#{bypass.port}/")

    {:ok, bypass: bypass}
  end

  describe "/new command" do
    @new_game_payload %{
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
        "text" => "/new@ex_truco_bot"
      },
      "update_id" => 863_667_915
    }

    test "responds ok to telegram request", %{bypass: bypass} do
      # Stub message sent back to telegram.
      Bypass.expect(bypass, "POST", "/token/sendMessage", fn conn ->
        Plug.Conn.resp(conn, 200, "ok")
      end)

      conn = conn(:post, "/telegram/<token>", @new_game_payload)
      conn = TelegramBot.Endpoint.call(conn, @opts)

      assert conn.state == :sent
      assert conn.status == 200
      assert conn.resp_body == "ok"
    end
  end
end
