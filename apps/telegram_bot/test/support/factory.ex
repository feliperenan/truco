defmodule TelegramBot.Factory do
  alias TelegramBot.{Message, InlineQuery}

  def build(:telegram_message_chat) do
    %Message.Chat{
      all_members_are_administrators: true,
      id: 419_752_573,
      title: "truco-test",
      type: "group"
    }
  end

  def build(:user) do
    %TelegramBot.User{
      first_name: "Felipe",
      id: 111_111_111,
      is_bot: false,
      username: "feliperenan",
      language_code: "en",
      last_name: "Renan"
    }
  end

  def build(:telegram_message) do
    %Message{
      chat: build(:telegram_message_chat),
      date: 1_605_212_571,
      from: build(:user),
      message_id: nil,
      text: "/start"
    }
  end

  def build(:inline_query) do
    %InlineQuery{
      from: build(:user),
      id: "3975448342490274657",
      offset: "",
      query: "",
      update_id: nil
    }
  end

  def build(factory_name, attrs) do
    factory_name
    |> build()
    |> struct!(attrs)
  end
end
