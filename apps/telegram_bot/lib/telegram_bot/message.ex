defmodule TelegramBot.Message do
  @moduledoc """
  Provide functions for handling Telegram messages.
  """

  defstruct [:chat, :date, :from, :message_id, :text]

  @type t() :: %__MODULE__{}

  @doc """
  Builds a `Message` struct from the given message payload.

  ### Examples

    message_payload = %{
       "message" => %{
         "chat" => %{
           "all_members_are_administrators" => true,
           "id" => -419_752_573,
           "title" => "truco-test",
           "type" => "group"
         },
         "date" => 1_605_212_571,
         "entities" => [%{"length" => 19, "offset" => 0, "type" => "bot_command"}],
         "from" => %{
           "first_name" => "Felipe",
           "id" => 925_606_196,
           "is_bot" => false,
           "language_code" => "en",
           "last_name" => "Renan"
         },
         "message_id" => 16,
         "text" => "/start@ex_truco_bot"
       },
       "update_id" => 863_667_915
     }

     Message.new(message_payload)
     #=> %Message{...}
  """
  @spec new(map()) :: t()
  def new(%{"message" => message}) do
    message_payload =
      message
      |> transform_to_atom_keys()
      |> remove_bot_suffix_from_text()

    struct(__MODULE__, message_payload)
  end

  defp transform_to_atom_keys(map) when is_map(map) do
    Map.new(map, fn
      {"from", v} -> {:from, TelegramBot.User.new(v)}
      {"chat", v} -> {:chat, TelegramBot.Chat.new(v)}
      {k, v} -> {String.to_atom(k), transform_to_atom_keys(v)}
    end)
  end

  defp transform_to_atom_keys(value), do: value

  defp remove_bot_suffix_from_text(%{text: text} = message),
    do: %{message | text: String.replace(text, "@ex_truco_bot", "")}

  defp remove_bot_suffix_from_text(message), do: message
end
