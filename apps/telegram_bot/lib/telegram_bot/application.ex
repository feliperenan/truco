defmodule TelegramBot.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children =
      [
        {Plug.Cowboy, scheme: :http, plug: TelegramBot.Endpoint, options: [port: port()]},
        start_telegram_client_mock_server(),
        start_game_manager()
      ]
      |> Enum.reject(&is_nil/1)

    opts = [strategy: :one_for_one, name: TelegramBot.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def port, do: Application.get_env(:telegram_bot, :port, 4000)

  # Start mock server only on test env.
  defp start_telegram_client_mock_server do
    case Mix.env() do
      :test ->
        {Plug.Cowboy, scheme: :http, plug: TelegramBot.TelegramClient.MockServer, options: [port: 8081]}

      _ ->
        nil
    end
  end

  # Do not start game manager on the test env.
  defp start_game_manager do
    case Mix.env() do
      :test ->
        nil

      _ ->
        {TelegramBot.GameManager, %{}}
    end
  end
end
