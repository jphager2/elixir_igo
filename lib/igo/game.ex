alias Igo.Board, as: Board
alias Igo.Player, as: Player
alias Igo.Printer, as: Printer

defmodule Igo.Game do
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
    if length(game[:moves]) > 0 do
      { move, game } = pop_move(game)
      game = update_board(game, move[:board])

      game =
        if move[:pass] do
          update_passes(game, game[:passes] - 1)
        else
          game
        end

      update_player(game, move[:color], move[:captures] * -1)
    else
      game
    end
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

  defp update_board(game, board) do
    Map.update!(game, :board, fn old_board ->
      if length(board) == length(old_board) do
        board
      else
        old_board
      end
    end)
  end

  defp update_passes(game, passes) do
    Map.update!(game, :passes, fn _old_passes ->
      passes
    end)
  end

  defp push_move(game, move) do
    Map.update!(game, :moves, fn moves ->
      moves ++ [move]
    end)
  end

  defp pop_move(game) do
    Map.get_and_update(game, :moves, fn moves ->
      List.pop_at(moves, -1)
    end)
  end
end
