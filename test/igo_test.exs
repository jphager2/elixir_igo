defmodule IgoTest do
  use ExUnit.Case
  doctest Igo

  test "greets the world" do
    assert Igo.hello() == :world
  end
end
