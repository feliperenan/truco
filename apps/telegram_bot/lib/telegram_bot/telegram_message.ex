defmodule TelegramBot.TelegramMessage do
  defmodule Chat do
    defstruct [:all_members_are_administrators, :id, :title, :type]
  end

  defmodule From do
    defstruct [:first_name, :id, :is_bot, :language_code, :last_name]
  end

  @moduledoc """
  Represents a telegram message which is parsed from the following payload:

    payload = %{
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

  This message is sent by Telegram API through webhook.
  """
  defstruct [:chat, :date, :from, :id, :text]

  @type t() :: %__MODULE__{}

  @doc """
  Converts the given payload to __MODULE__ struct.
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
    Map.new(map, fn {k, v} -> {String.to_atom(k), transform_to_atom_keys(v)} end)
  end

  defp transform_to_atom_keys(value), do: value

  defp remove_bot_suffix_from_text(%{text: text} = message),
    do: %{message | text: String.replace(text, "@ex_truco_bot", "")}

  defp remove_bot_suffix_from_text(message), do: message
end
