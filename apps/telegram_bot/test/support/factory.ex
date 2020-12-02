defmodule TelegramBot.Factory do
  alias TelegramBot.TelegramMessage

  def build(:telegram_message_chat) do
    %TelegramMessage.Chat{
      all_members_are_administrators: true,
      id: 419_752_573,
      title: "truco-test",
      type: "group"
    }
  end

  def build(:telegram_message_from) do
    %TelegramMessage.From{
      first_name: "Felipe",
      id: 111_111_111,
      is_bot: false,
      username: "feliperenan",
      language_code: "en",
      last_name: "Renan"
    }
  end

  def build(:telegram_message) do
    %TelegramMessage{
      chat: build(:telegram_message_chat),
      date: 1_605_212_571,
      from: build(:telegram_message_from),
      message_id: nil,
      text: "/start"
    }
  end

  def build(factory_name, attrs) do
    factory_name
    |> build()
    |> struct!(attrs)
  end
end
