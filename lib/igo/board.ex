alias Igo.Stone, as: Stone
alias Igo.Printer, as: Printer

defmodule Igo.Board do
  def new(size) do
    initialize(size * size, [])
  end

  def initialize(size, board) when size <= 0 do
    board
  end

  def initialize(size, board) do
    initialize(size - 1, board ++ [:liberty])
  end

  def place_stone(board, color, coord) do
    index = board_index(board, coord)
    board = List.replace_at(board, index, color)
    capture_stones(board, Stone.opposite_color(color), coord)
  end

  def capture_stones(board, capture_color, coord) do
    coords = coords_around(board, coord)
    captures = Enum.reduce(coords, [], fn(next_coord, group) ->
      coord_group = stone_group_without_liberties(board, next_coord, capture_color, group)

      if coord_group == :liberty do
        group
      else
        coord_group
      end
    end)

    board = remove_stones(board, captures)

    { board, length(captures) }
  end

  def stone_group_without_liberties(board, coord) do
    group = [coord]
    color = at_coord(board, coord)

    if color == :liberty do
      :liberty
    else
      coords = coords_around(board, coord)
      Enum.reduce(coords, group, fn(next_coord, new_group) ->
        stone_group_without_liberties(board, next_coord, color, new_group)
      end)
    end
  end

  def stone_group_without_liberties(board, coord, color, group) do
    if group == :liberty do
      :liberty
    else
      next_color = at_coord(board, coord)

      cond do
        next_color == :liberty ->
          :liberty
        next_color == color ->
          if Enum.member?(group, coord) do
            group
          else
            coords = coords_around(board, coord)
            Enum.reduce(coords, group ++ [coord], fn(next_coord, new_group) ->
              stone_group_without_liberties(board, next_coord, color, new_group)
            end)
          end
        true ->
          group
      end
    end
  end

  def territory_group_with_dead_stones(board, coord, color, { territory, dead_stones }) do
    next_color = at_coord(board, coord)

    if next_color == color do
      { territory, dead_stones }
    else
      dead_stones =
        if next_color != :liberty && !Enum.member?(dead_stones, coord) do
          dead_stones ++ [coord]
        else
          dead_stones
        end

      if Enum.member?(territory, coord) do
        { territory, dead_stones }
      else
        coords = coords_around(board, coord)

        Enum.reduce(coords, { territory ++ [coord], dead_stones } , fn(next_coord, state) ->
          territory_group_with_dead_stones(board, next_coord, color, state)
        end)
      end
    end
  end

  def coords_around(board, { y, x }) do
    coords = [
      { y - 1, x },
      { y, x + 1 },
      { y + 1, x },
      { y, x - 1 }
    ]

    Enum.filter(coords, fn({ y, x }) ->
      y >= 0 && y < size(board) && x >= 0 && x < size(board)
    end)
  end

  def remove_stones(board, coords) do
    Enum.reduce(coords, board, fn(coord, board) ->
      index = board_index(board, coord)
      List.replace_at(board, index, :liberty)
    end)
  end

  def at_coord(board, coord) do
    index = board_index(board, coord)
    Enum.at(board, index)
  end

  def star?(size, { y, x }) do
    middle = (size - 1) / 2

    cond do
      size < 9 && size >= 3 ->
        y == middle && x == middle
      size < 13 ->
        ((y == 2 || y == 6) && (x == 2 || x == 6)) || (y == 4 && x == 4)
      size >= 13 ->
        bottom = size - 4
        (y == 3 || y == middle || y == bottom) && (x == 3 || x == middle || x == bottom)
    end
  end

  def size(board) do
    round(:math.sqrt(length(board)))
  end

  def board_index(board, { y, x }) do
    size(board) * y + x
  end

  def print(board) do
    Printer.print_rows(Enum.chunk_every(board, size(board)))
  end
end
