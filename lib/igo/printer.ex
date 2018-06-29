alias Igo.Board, as: Board

defmodule Igo.Printer do
  @colors %{ liberty: "-", black: "◯", white: "⬤" }

  def puts(msg) do
    IO.puts(msg)
  end

  def print(msg) do
    IO.write(msg)
  end

  def print_color(color) do
    print(@colors[color])
  end

  def print_star do
    print("*")
  end

  def print_row(row, row_index) do
    if row_index >= 10 do
      print(row_index)
    else
      print("#{row_index} ")
    end

    Enum.reduce(row, 0, fn(color, col_index) ->
      if color == :liberty && Board.star?(length(row), { row_index, col_index }) do
        print_star()
      else
        print_color(color)
      end
      print(" ")

      col_index + 1
    end)
    puts("")
  end

  def print_numbers(max, current) when current >= max do
    puts(current)
  end

  def print_numbers(max, current) do
    if current >= 10 do
      print(current)
    else
      print("#{current} ")
    end
    print_numbers(max, current + 1)
  end

  def print_rows(rows) do
    print("  ")
    print_numbers(length(rows) - 1, 0)
    Enum.reduce(rows, 0, fn(row, index) ->
      print_row(row, index)
      index + 1
    end)
  end
end
