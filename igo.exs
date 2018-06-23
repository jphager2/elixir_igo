defmodule Igo do
  @coord_regex ~r{(?<row>\d+), (?<col>\d+).*}
  @pass_regex ~r{.*pass.*}

  def play do
    size = get_size()
    game = Game.new(size)
    play(game)
  end

  def play(game) do
    Game.print(game)

    color = Game.turn(game)
    move = get_move(color)
    game =
      if move == :pass do
        Game.pass(game, color)
      else
        cond do
          Rules.play_on_stone?(game, move) ->
            print_error("You can't play on top of a stone!")
            game
          Rules.ko?(game, move, color) ->
            print_error("You can't play the ko!")
            game
          true ->
            game = Game.play(game, color, move)

            if Rules.suicide?(game, move) do
              print_error("You can't play a suicide move!")
              Game.undo(game)
            else
              game
            end
        end
      end

    if Rules.game_over?(game) do
      print_result(game)
      Printer.puts("Game Over! Time to count :D!")
    else
      play(game)
    end
  end

  def get_move(color) do
    input = IO.gets("#{color}'s turn. Enter move (e.g. 2, 2 OR pass): ")
    coord = Regex.named_captures(@coord_regex, input)

    cond do
      Regex.match?(@pass_regex, input) ->
        :pass
      coord ->
        { String.to_integer(coord["row"]), String.to_integer(coord["col"]) }
      true ->
        get_move(color)
    end
  end

  def get_size do
    result = Integer.parse(IO.gets("Enter a board size (9, 13, 19): "))

    if result == :error do
      get_size()
    else
      elem(result, 0)
    end
  end

  def print_result(game) do
    Game.print(game)
  end

  def print_error(msg) do
    Printer.puts(msg)
  end
end

defmodule Rules do
  def game_over?(game) do
    game[:passes] >= 2
  end
  
  def play_on_stone?(game, move) do
    board = game[:board]
    Board.at_coord(board, move) != :liberty
  end

  def suicide?(game, move) do
    board = game[:board]
    Board.stone_group_without_liberties(board, move) != :liberty
  end

  # NOTE: I'm not sure about this logic...
  def ko?(game, move, color) do
    last_move = Enum.at(game[:moves], -1)
    board = last_move[:board]

    last_move[:captures] == 1 && Board.at_coord(board, move) == color
  end
end

defmodule Printer do
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

  def print_chunk(chunk) do
    Enum.each(chunk, fn color ->
      print_color(color) 
      print(" ")
    end)
    puts("")
  end

  def print_chunks(chunks) do
    Enum.each(chunks, fn chunk -> print_chunk(chunk) end)
  end
end

defmodule Player do
  def print(player) do
    Printer.print(Enum.join([player[:name], "(", player[:captures], ")"]))
  end
end

defmodule Stone do
  def opposite_color(color) do
    if color == :black do
      :white
    else
      :black
    end
  end
end

defmodule Board do
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

  def size(board) do
    round(:math.sqrt(length(board)))
  end

  def board_index(board, { y, x }) do
    size(board) * y + x
  end

  def print(board) do
    Printer.print_chunks(Enum.chunk_every(board, size(board)))
  end
end

defmodule Game do
  def new(board_size) do
    board = Board.new(board_size)

    %{
      black: %{ captures: 0, name: 'Black' },
      white: %{ captures: 0, name: 'White' },
      moves: [],
      passes: 0,
      board: board
    }
  end

  def update_player(game, color, captures) when is_integer(captures) do
    Map.update!(game, color, fn player ->
      %{ captures: player[:captures] + captures, name: player[:name] }
    end)
  end

  def update_player(game, color, name) do
    Map.update!(game, color, fn player ->
      %{ captures: player[:captures], name: name }
    end)
  end

  def update_board(game, board) do
    Map.update!(game, :board, fn old_board ->
      if length(board) == length(old_board) do
        board
      else
        old_board
      end
    end)
  end

  def update_passes(game, passes) do
    Map.update!(game, :passes, fn _old_passes ->
      passes
    end)
  end

  def push_move(game, move) do
    Map.update!(game, :moves, fn moves ->
      moves ++ [move]
    end)
  end

  def pop_move(game) do
    Map.get_and_update(game, :moves, fn moves ->
      List.pop_at(moves, -1)
    end)
  end

  def play(game, color, coord) do
    board = game[:board]
    { new_board, captures } = Board.place_stone(board, color, coord)
    game = update_board(game, new_board)
    game = update_player(game, color, captures)
    game = update_passes(game, 0)
    push_move(game, %{ color: color, coord: coord, captures: captures, board: board })
  end

  def pass(game, color) do
    board = game[:board]
    game = update_passes(game, game[:passes] + 1)
    push_move(game, %{ color: color, pass: true, captures: 0, board: board })
  end

  def undo(game) do
    { move, game } = pop_move(game)
    game = update_board(game, move[:board])

    game =
      if move[:pass] do
        update_passes(game, game[:passes] - 1)
      else
        game
      end

    update_player(game, move[:color], move[:captures] * -1)
  end

  def turn(game) do
    if rem(length(game[:moves]), 2) == 0 do
      :black
    else
      :white
    end
  end

  def print(game) do
    Player.print(game[:black])
    Printer.print(" | ")
    Player.print(game[:white])
    Printer.print(" | Passes: #{game[:passes]}")
    Printer.print(" | Moves: #{length(game[:moves])}")
    Printer.puts("")

    Board.print(game[:board])
  end
end

# game = Game.new(19)
# game = Game.update_player(game, :black, 'John')
# game = Game.update_player(game, :white, 'Tereza')

# game = Game.play(game, :black, { 2, 2 })
# game = Game.play(game, :white, { 6, 6 })
# game = Game.play(game, :black, { 6, 2 })
# game = Game.play(game, :white, { 2, 6 })
# game = Game.pass(game, :black)
# game = Game.undo(game)
# game = Game.pass(game, :black)
# game = Game.play(game, :white, { 16, 16 })

# Game.print(game)

Igo.play
