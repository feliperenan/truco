defmodule TelegramBot.Integrations.WebhookTest do
  use TelegramBot.DataCase
  use Plug.Test

  alias TelegramBot.WebhookPayloadMock

  @opts TelegramBot.Endpoint.init([])

  # Make a post request to our exposed endpoint simulating a Telegram webhook post request.
  #
  # It takes a webhook payload that can be generated by `WebhookPayloadMock` module.
  defp webhook_post(webhook_payload) do
    :post
    |> conn("/telegram/<token>", webhook_payload)
    |> TelegramBot.Endpoint.call(@opts)
  end

  defp assert_webhook_response(conn) do
    assert conn.state == :sent
    assert conn.status == 200
    assert conn.resp_body == "ok"
  end

  setup [:start_game_engine, :start_game_manager]

  test "receives a telegram message" do
    telegram_message = WebhookPayloadMock.message(text: "/new", type: :group)

    telegram_message
    |> webhook_post()
    |> assert_webhook_response()
  end

  test "receives a telegram inline query" do
    inline_query = WebhookPayloadMock.inline_query()

    inline_query
    |> webhook_post()
    |> assert_webhook_response()
  end
end
