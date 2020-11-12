defmodule TelegramClient.Endpoint do
  use Plug.Router

  require Logger

  plug Plug.Parsers, parsers: [:json], json_decoder: Jason
  plug :match
  plug :dispatch

  # Ping endpoint for checking API status.
  get "/ping" do
    send_resp(conn, 200, "pong")
  end

  # Just print body params sent by telegram webhook for now. Here is a Telegram post sample:
  #
  #  curl -X POST -H "Content-Type: application/json" -H '{
  #    "update_id":10000,
  #    "message":{
  #      "date":1441645532,
  #      "chat":{
  #         "last_name":"Test Lastname",
  #         "id":1111111,
  #         "first_name":"Test",
  #         "username":"Test"
  #      },
  #      "message_id":1365,
  #      "from":{
  #         "last_name":"Test Lastname",
  #         "id":1111111,
  #         "first_name":"Test",
  #         "username":"Test"
  #      },
  #      "text":"/start"
  #    }
  #    }' "http://localhost:4001/telegram/token"
  post "/telegram/:token" do
    Logger.info(~s"""
      received from Telegram:

      #{inspect(conn.body_params)}
    """)

    send_resp(conn, 200, "ok")
  end

  match _ do
    send_resp(conn, 404, "not found.")
  end
end
