defmodule TelegramBot.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children =
      [
        {Plug.Cowboy, scheme: :http, plug: TelegramBot.Endpoint, options: [port: port()]},
        start_telegram_client_mock_server(Mix.env())
      ]
      |> Enum.reject(&is_nil/1)

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: TelegramBot.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def port, do: Application.get_env(:telegram_bot, :port, 4000)

  defp start_telegram_client_mock_server(:test) do
    {Plug.Cowboy, scheme: :http, plug: TelegramBot.TelegramClient.MockServer, options: [port: 8081]}
  end

  defp start_telegram_client_mock_server(_), do: nil
end
