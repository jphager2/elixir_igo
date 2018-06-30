alias Igo.Game, as: Game
alias Igo.Rules, as: Rules
alias Igo.GoKifu, as: GoKifu
alias Igo.Printer, as: Printer
alias Igo.SgfReader, as: SgfReader

defmodule Igo do
  @moduledoc """
  Documentation for Igo.
  """

  @coord_regex ~r{(?<row>\d+), (?<col>\d+).*}
  @pass_regex ~r{.*pass.*}
  @done_regex ~r{.*done.*}
  @undo_regex ~r{.*undo.*}
  @stop_regex ~r{.*stop.*}
  @next_regex ~r{\An(ext)?.*}
  @previous_regex ~r{\Ap(revious)?}
  @index_regex ~r{\d+}

  @doc """
  Start an interaction to play a game. You will be asked for a board size,
  then the game will begin. You will be prompted for each move. When the 
  game is over, you will be asked to identify each player's territory, and
  then it will be counted.

  ## Examples

      iex> Igo.play

  """
  def play do
    size = get_size()
    game = Game.new(size)
    play(game)
  end

  @doc """
  Start an interaction to review a game. You will be prompted to enter the
  file path of an SGF file, and then will be able to navigate through the
  game file.

  ## Examples

      iex> Igo.review

  """
  def review do
    file = get_sgf_file()
    reader = SgfReader.new(file)

    review(reader)
  end

  @doc """
  Get games from gokifu.com.

  ## Examples

      iex> Igo.gokifu

  """
  def gokifu do
    games = GoKifu.get_games()

    Enum.reduce(games, 1, fn game, i ->
      {black, white, date, result, _} = game
      Printer.print(String.pad_leading(to_string(i), 5))
      Printer.print(") ")
      Printer.print_color(:black)
      Printer.print(" #{black} | ")
      Printer.print_color(:white)
      Printer.print(" #{white} | #{date} | #{result}")
      Printer.puts("")
      i + 1
    end)

    index = get_index()

    if index != :stop && index > 0 && index <= length(games) do
      game = Enum.at(games, index - 1)
      GoKifu.download_game(game)

      file = GoKifu.download_path(game)
      reader = SgfReader.new(file)

      review(reader)
    end
  end

  defp get_index do
    index = String.trim(IO.gets("Pick a game: "))

    cond do
      Regex.match?(@index_regex, index) ->
        String.to_integer(index)

      true ->
        :stop
    end
  end

  defp review(reader) do
    SgfReader.print(reader)

    index = get_seek_index()

    reader =
      cond do
        index == :next ->
          SgfReader.next(reader)

        index == :previous ->
          SgfReader.previous(reader)

        index == :stop ->
          :stop

        is_integer(index) ->
          SgfReader.seek(reader, index)

        true ->
          reader
      end

    if reader == :stop do
      Printer.puts("Sayonara")
    else
      review(reader)
    end
  end

  defp get_sgf_file do
    String.trim(IO.gets("Enter a file name: "))
  end

  defp get_seek_index do
    index = String.trim(IO.gets("Seek to move (e.g. next, previous, 42, stop): "))

    cond do
      Regex.match?(@next_regex, index) ->
        :next

      Regex.match?(@previous_regex, index) ->
        :previous

      Regex.match?(@index_regex, index) ->
        String.to_integer(index)

      Regex.match?(@stop_regex, index) ->
        :stop

      true ->
        :continue
    end
  end

  defp play(game) do
    Game.print(game)

    color = Game.turn(game)
    move = get_move(color)

    game =
      cond do
        move == :pass ->
          Game.pass(game, color)

        move == :undo ->
          Game.undo(game)

        true ->
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
      Printer.puts("Game Over! Time to count :D!")

      Game.print(game)
      black = get_territory_groups(:black, [])
      Game.print(game)
      white = get_territory_groups(:white, [])

      {black_territory, black_dead_stones} = Rules.count_territory(game, :black, black)
      {white_territory, white_dead_stones} = Rules.count_territory(game, :white, white)

      game = Game.update_player(game, :black, black_dead_stones)
      game = Game.update_player(game, :white, white_dead_stones)

      print_result(game, {black_territory, white_territory}, 6.5)
    else
      play(game)
    end
  end

  defp get_move(color) do
    input = IO.gets("It's #{color}'s turn. Enter move (e.g. 2, 2 OR pass OR undo): ")
    coord = Regex.named_captures(@coord_regex, input)

    cond do
      Regex.match?(@pass_regex, input) ->
        :pass

      Regex.match?(@undo_regex, input) ->
        :undo

      coord ->
        {String.to_integer(coord["row"]), String.to_integer(coord["col"])}

      true ->
        get_move(color)
    end
  end

  defp get_size do
    result = Integer.parse(IO.gets("Enter a board size (9, 13, 19): "))

    if result == :error do
      get_size()
    else
      elem(result, 0)
    end
  end

  defp get_territory_groups(color, group) do
    input = IO.gets("Mark #{color}'s territory (e.g. 2, 2 OR done): ")
    coord_match = Regex.named_captures(@coord_regex, input)

    cond do
      Regex.match?(@done_regex, input) ->
        group

      coord_match ->
        coord = {
          String.to_integer(coord_match["row"]),
          String.to_integer(coord_match["col"])
        }

        get_territory_groups(color, group ++ [coord])

      true ->
        get_territory_groups(color, group)
    end
  end

  defp print_result(game, {black_territory, white_territory}, komi) do
    Game.print(game)

    black_points = game[:black][:captures] + black_territory
    white_points = game[:white][:captures] + white_territory + komi

    winner =
      cond do
        black_points > white_points ->
          :black

        black_points < white_points ->
          :white

        true ->
          :tie
      end

    Printer.print("Black: #{black_points}, White: #{white_points}")

    if komi > 0 do
      Printer.puts(" (komi: #{komi})")
    else
      Printer.puts("")
    end

    if winner == :tie do
      Printer.puts("The result is a tie!")
    else
      Printer.puts("The winner is #{winner}!")
    end
  end

  defp print_error(msg) do
    Printer.puts(msg)
  end
end
