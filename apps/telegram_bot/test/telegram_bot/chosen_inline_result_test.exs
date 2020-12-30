defmodule TelegramBot.ChosenInlineResultTest do
  use TelegramBot.DataCase

  alias TelegramBot.ChosenInlineResult

  describe "new/1" do
    test "builds an chosen inline result struct from a payload" do
      chosen_inline_result_payload = %{
        "chosen_inline_result" => %{
          "from" => %{
            "first_name" => "Felipe",
            "id" => 111_111_111,
            "is_bot" => false,
            "language_code" => "en",
            "last_name" => "Renan",
            "username" => "feeliperenan"
          },
          "query" => "",
          "result_id" => "Q-clubs"
        },
        "update_id" => 863_668_693
      }

      assert %ChosenInlineResult{
               from: %TelegramBot.User{
                 first_name: "Felipe",
                 id: 111_111_111,
                 is_bot: false,
                 language_code: "en",
                 last_name: "Renan",
                 username: "feeliperenan"
               },
               query: "",
               result_id: "Q-clubs"
             } == ChosenInlineResult.new(chosen_inline_result_payload)
    end
  end

  describe "build_reply/1" do
    setup [:start_game_engine, :start_game_manager]

    setup _context do
      chat = build(:chat, type: "group")
      user_a = build(:user, id: 1, username: "user-1")
      user_b = build(:user, id: 2, username: "user-2")

      new_game()
      join_player(chat, user_a)
      join_player(chat, user_b)
      start_game(chat, user_a)

      %{chat: chat, user_a: user_a, user_b: user_b}
    end

    def build_result_id(user) do
      {:ok, game_id} = TelegramBot.GameManager.get_game_id(user_id: user.id)
      {:ok, %{cards: [card | _rest]}} = Engine.get_player_hand(game_id, user.username)

      "#{card.symbol}-#{card.suit}"
    end

    test "play the card the user card from a chosen inline result", %{chat: chat, user_a: user_a, user_b: user_b} do
      result_id = build_result_id(user_a)
      chosen_inline_result = build(:chosen_inline_result, result_id: result_id, from: user_a)

      reply = ChosenInlineResult.build_reply(chosen_inline_result)

      assert reply.to == Integer.to_string(chat.id)
      assert reply.text == "Now is @#{user_b.username} turn."
      assert reply.reply_markup 
    end

    test "raise an error a card is not found", %{user_a: user} do
      chosen_inline_result = build(:chosen_inline_result, result_id: "Q-clubs", from: user)

      error_message = "There is an error when replying a chosen inline result: {:error, :card_not_found}"
      assert_raise ChosenInlineResult.Error, error_message, fn ->
        ChosenInlineResult.build_reply(chosen_inline_result)
      end
    end

    test "raise an error when a game is not found from the given user" do
      chosen_inline_result = build(:chosen_inline_result, result_id: "Q-clubs", from: build(:user, id: 99999))

      error_message = "There is an error when replying a chosen inline result: {:error, :game_not_found}"
      assert_raise ChosenInlineResult.Error, error_message, fn ->
        ChosenInlineResult.build_reply(chosen_inline_result)
      end
    end
  end
end
