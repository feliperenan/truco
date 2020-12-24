defmodule ImageUploader.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      ImageUploader.Repo
      # Start a worker by calling: ImageUploader.Worker.start_link(arg)
      # {ImageUploader.Worker, arg}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: ImageUploader.Supervisor)
  end
end
