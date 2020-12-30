defmodule TelegramBot.InlineQueryTest do
  use ExUnit.Case

  alias TelegramBot.InlineQuery
  alias TelegramBot.User
  alias TelegramBot.MessageHandler

  import TelegramBot.Factory

  defp start_game_engine(_context) do
    start_supervised!(%{
      id: Engine.Application,
      start: {Engine.Application, :start, [nil, nil]}
    })

    :ok
  end

  defp start_game_manager(_context) do
    start_supervised!({TelegramBot.GameManager, %{}})

    :ok
  end

  defp new_game do
    :message
    |> build(text: "/new")
    |> MessageHandler.process_message()
  end

  defp join_player(chat, user) do
    :message
    |> build(text: "/join", from: user, chat: chat)
    |> MessageHandler.process_message()
  end

  defp start_game(chat, user) do
    :message
    |> build(text: "/start", chat: chat, from: user)
    |> MessageHandler.process_message()
  end

  describe "new/1" do
    test "builds an inline query struct given a inline query payload" do
      inline_query_payload = %{
        "inline_query" => %{
          "from" => %{
            "first_name" => "Felipe",
            "id" => 111_111_111,
            "is_bot" => false,
            "language_code" => "en",
            "last_name" => "Renan",
            "username" => "feliperenan"
          },
          "id" => "3975448342490274657",
          "offset" => "",
          "query" => ""
        },
        "update_id" => 863_668_430
      }

      assert %InlineQuery{
               from: %User{
                 first_name: "Felipe",
                 id: 111_111_111,
                 is_bot: false,
                 language_code: "en",
                 last_name: "Renan",
                 username: "feliperenan"
               },
               id: "3975448342490274657",
               offset: "",
               query: "",
               update_id: nil
             } == InlineQuery.new(inline_query_payload)
    end
  end

  describe "build_reply" do
    setup [:start_game_engine, :start_game_manager]

    setup _context do
      chat = build(:chat, type: "group")
      user_a = build(:user, id: 1, username: "user-1")
      user_b = build(:user, id: 2, username: "user-2")

      new_game()
      join_player(chat, user_a)
      join_player(chat, user_b)
      start_game(chat, user_a)

      %{user_a: user_a, user_b: user_b}
    end

    test "send cards to the User who requested it", %{user_a: user} do
      inline_query = build(:inline_query, from: user)
      get_image_by = fn key: _key -> %ImageUploader.Image{} end
      inline_query_reply = InlineQuery.build_reply(inline_query, get_image_by: get_image_by)

      assert inline_query_reply.inline_query_id == inline_query.id
      assert length(inline_query_reply.results) == 3
    end

    test "send an empty result to the User when it is not his turn", %{user_b: user} do
      inline_query = build(:inline_query, from: user)
      inline_query_reply = InlineQuery.build_reply(inline_query)

      assert inline_query_reply.inline_query_id == inline_query.id
      assert Enum.empty?(inline_query_reply.results)
    end
  end
end
