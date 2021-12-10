defmodule HomeAssistantEngineTest do
  use ExUnit.Case
  doctest HomeAssistantEngine

  test "greets the world" do
    assert HomeAssistantEngine.hello() == :world
  end
end
