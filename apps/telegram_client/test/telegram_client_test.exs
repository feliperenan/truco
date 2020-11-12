defmodule TelegramClientTest do
  use ExUnit.Case
  doctest TelegramClient

  test "greets the world" do
    assert TelegramClient.hello() == :world
  end
end
