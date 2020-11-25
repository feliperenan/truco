defmodule TelegramBot.TelegramClient.MockServer do
  use Plug.Router

  plug Plug.Parsers, parsers: [:json, :urlencoded], pass: ["text/*"], json_decoder: Jason
  plug :match
  plug :dispatch

  post "/token/sendMessage" do
    Plug.Conn.send_resp(conn, 200, Jason.encode!(conn.params))
  end
end
