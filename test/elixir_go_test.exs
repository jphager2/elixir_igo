defmodule ElixirGoTest do
  use ExUnit.Case
  doctest ElixirGo

  test "greets the world" do
    assert ElixirGo.hello() == :world
  end
end
