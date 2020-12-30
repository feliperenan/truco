defmodule TelegramBot.DataCase do
  use ExUnit.CaseTemplate, async: true

  using do
    quote do
      import TelegramBot.Factory
      import TelegramBot.Helpers
    end
  end
end
