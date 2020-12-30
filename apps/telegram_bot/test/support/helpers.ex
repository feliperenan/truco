defmodule TelegramBot.Helpers do
  def start_game_engine(_context) do
    ExUnit.Callbacks.start_supervised!(%{
      id: Engine.Application,
      start: {Engine.Application, :start, [nil, nil]}
    })
    :ok
  end

  def start_game_manager(_context) do
    ExUnit.Callbacks.start_supervised!({TelegramBot.GameManager, %{}})
    :ok
  end

  def new_game do
    :message
    |> TelegramBot.Factory.build(text: "/new")
    |> TelegramBot.Message.build_reply()
  end

  def join_player(chat, user) do
    :message
    |> TelegramBot.Factory.build(text: "/join", from: user, chat: chat)
    |> TelegramBot.Message.build_reply()
  end

  def start_game(chat, user) do
    :message
    |> TelegramBot.Factory.build(text: "/start", chat: chat, from: user)
    |> TelegramBot.Message.build_reply()
  end
end
