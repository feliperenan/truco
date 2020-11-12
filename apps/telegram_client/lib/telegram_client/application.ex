defmodule TelegramClient.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      {Plug.Cowboy, scheme: :http, plug: TelegramClient.Endpoint, options: [port: 4000]}
    ]

    IO.inspect "hiiii"

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: TelegramClient.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
