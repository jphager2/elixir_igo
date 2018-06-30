alias Igo.Board, as: Board

defmodule Igo.Rules do
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

  def ko?(game, move, color) do
    last_move = Enum.at(game[:moves], -1)
    board = last_move[:board]

    last_move[:captures] == 1 && Board.at_coord(board, move) == color
  end

  def count_territory(game, color, groups) do
    board = game[:board]

    {territory, dead_stones} =
      Enum.reduce(groups, {[], []}, fn coord, counts ->
        Board.territory_group_with_dead_stones(board, coord, color, counts)
      end)

    {length(territory), length(dead_stones)}
  end
end
