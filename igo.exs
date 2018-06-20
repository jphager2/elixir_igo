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

defmodule Igo do
end

defmodule Player do
  def print(player) do
    Printer.print(Enum.join([player[:name], "(", player[:captures], ")"]))
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

  def place_stone(board, color, { x, y }) do
    index = size(board) * x + y
    List.replace_at(board, index, color)
  end

  def size(board) do
    round(:math.sqrt(length(board)))
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
    captures = 1
    board = game[:board]
    game = update_board(game, Board.place_stone(game[:board], color, coord))
    # TODO: Assess rules and capture stones
    game = update_player(game, color, captures)
    push_move(game, %{ color: color, coord: coord, captures: captures, board: board })
  end

  def undo(game) do
    { move, game } = pop_move(game)
    game = update_board(game, move[:board])
    update_player(game, move[:color], move[:captures] * -1)
  end

  def print(game) do
    Player.print(game[:black])
    Printer.print(" | ")
    Player.print(game[:white])
    Printer.puts("")

    Board.print(game[:board])
  end
end

game = Game.new(19)
game = Game.update_player(game, :black, 'John')
game = Game.update_player(game, :white, 'Tereza')

game = Game.play(game, :black, { 2, 2 })
game = Game.play(game, :white, { 6, 6 })
game = Game.play(game, :black, { 6, 2 })
game = Game.play(game, :white, { 2, 6 })
game = Game.undo(game)

Game.print(game)
