defmodule TelegramBot.WebhookPayloadMock do
  @moduledoc """
  Provide helper functions for creating webhook payloads to be used under tests.
  """

  @group_message_example %{
    "message" => %{
      "chat" => %{
        "all_members_are_administrators" => true,
        "id" => 222_222_222,
        "title" => "truco-test",
        "type" => "group"
      },
      "date" => 1_605_212_571,
      "entities" => [%{"length" => 19, "offset" => 0, "type" => "bot_command"}],
      "from" => %{
        "first_name" => "Felipe",
        "id" => 111_111_111,
        "is_bot" => false,
        "language_code" => "en",
        "last_name" => "Renan"
      },
      "message_id" => 16,
      "text" => "messsage"
    },
    "update_id" => 333_333_333
  }

  @private_message_example %{
    "message" => %{
      "chat" => %{
        "first_name" => "Felipe",
        "id" => 444_444_444,
        "last_name" => "Renan",
        "type" => "private"
      },
      "date" => 1_605_733_162,
      "from" => %{
        "first_name" => "Felipe",
        "id" => 555_555_555,
        "is_bot" => false,
        "language_code" => "en",
        "last_name" => "Renan"
      },
      "message_id" => 57,
      "text" => "message"
    },
    "update_id" => 999_999_999
  }

  @doc """
  Build an message example sent by Telegram webhook.

  ### Examples

      WebhookPayloadMock.message(text: "/new", type: :group)
      => %{"message" => %{...}}

  """
  def message(opts \\ []) do
    %{text: text, type: type} = Enum.into(opts, %{})

    build(type, text)
  end

  defp build(:group, text), do: put_in(@group_message_example, ["message", "text"], text)
  defp build(:private, text), do: put_in(@private_message_example, ["message", "text"], text)
  defp build(type, _message), do: raise("There is no payload for #{type}")
end
