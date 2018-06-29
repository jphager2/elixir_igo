defmodule Igo.Stone do
  def opposite_color(color) do
    if color == :black do
      :white
    else
      :black
    end
  end
end
