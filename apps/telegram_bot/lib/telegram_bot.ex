defmodule TelegramBot do
  alias TelegramBot.ChosenInlineResult
  alias TelegramBot.InlineQuery
  alias TelegramBot.Message

  require Logger

  @doc """
  Process the given command received from Telegram webhook and reply it properly.

  ### Commands

  - /new   - creates a new game in the chat group.
  - /join  - joins the sender to a game.
  - /start - starts a the game as long as it has enough players.
  - /leave - removes the sender from the game.

  ### Gameplay example

  Imagine there is a group created with: @ex-truco-bot, @felipe and @renan and below commands is
  executed inside a telegram app.

  felipe>
    /new

  ex-truco-bot>
    The game has been created and it is ready for receive players.

  felipe>
  /join

  ex-truco-bot>
    You have joined the game. Now, wait for other players or send /start to start the game in case
    you have enough players.

  renan>
    /join

  ex-truco-bot>
    You have joined the game. Now, wait for other players or send /start to start the game in case
    you have enough players.

  felipe>
    /start

  ex-truco-bot>
    The game has been started

    The card faced up is: 3 ♠️
    The player who starts is: @felipe
    |-------------------------------|
    |        Make your choice       |
    |-------------------------------|

  """
  @spec build_reply(map()) :: :ok
  def build_reply(%{"message" => _message} = message) do
    message
    |> Message.new()
    |> Message.build_reply()
    |> case do
      :ignore ->
        :ok

      %{to: to, text: text} = reply ->
        reply_markup = Map.get(reply, :reply_markup, %{})
        {:ok, _message} = Nadia.send_message(to, text, reply_markup: reply_markup)

        :ok
    end
  end

  def build_reply(%{"inline_query" => _inline_query} = inline_query) do
    reply =
      inline_query
      |> InlineQuery.new()
      |> InlineQuery.build_reply()

    Nadia.answer_inline_query(
      reply.inline_query_id,
      reply.results,
      cache_time: 0,
      is_personal: true
    )

    :ok
  end

  def build_reply(%{"chosen_inline_result" => _chosen_inline_result} = chosen_inline_result) do
    reply =
      chosen_inline_result
      |> ChosenInlineResult.new()
      |> ChosenInlineResult.build_reply()

    reply_markup = Map.get(reply, :reply_markup, %{})
    {:ok, _message} = Nadia.send_message(reply.to, reply.text, reply_markup: reply_markup)

    :ok
  end
end
