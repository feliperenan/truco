defmodule TelegramBot.MessageHandlerTest do
  use ExUnit.Case

  alias TelegramBot.WebhookPayloadMock
  alias TelegramBot.TelegramMessage
  alias TelegramBot.MessageHandler

  defp build_telegram_message(opts) do
    opts
    |> WebhookPayloadMock.message()
    |> TelegramMessage.new()
  end

  def start_game_engine(_context) do
    start_supervised!(%{
      id: Engine.Application,
      start: {Engine.Application, :start, [nil, nil]}
    })

    :ok
  end

  describe "process_message/1" do
    setup :start_game_engine

    test "/new create a new game" do
      telegram_message = build_telegram_message(text: "/new", type: :group)

      assert %{
               text: "The game has been created and it is ready for receive players.",
               to: 222_222_222
             } == MessageHandler.process_message(telegram_message)
    end

    test "/new does not start game on private conversation" do
      telegram_message = build_telegram_message(text: "/new", type: :private)

      text = ~s"""
      I can't start a game from a private conversation.

      In order to play the game, you need to create a group with people you want to play.
      """

      assert %{
               text: text,
               to: 444_444_444
             } == MessageHandler.process_message(telegram_message)
    end

    test "/new does not create twice" do
      build_telegram_message(text: "/new", type: :group)
      |> MessageHandler.process_message()

      telegram_message = build_telegram_message(text: "/new", type: :group)

      text = ~s"""
      There is already a game created for this group.

      Try /join to join the game or /start to start the game.
      """

      assert %{
               text: text,
               to: 222_222_222
             } == MessageHandler.process_message(telegram_message)
    end
  end
end
