alias Igo.Game, as: Game
alias Igo.Printer, as: Printer

defmodule Igo.SgfReader do
  @move_regex ~r{(?<color>B|W)\[(?<col>[a-s])(?<row>[a-s])\]}

  def new(file_path) do
    sgf = File.read!(file_path)

    meta = parse_meta(sgf)

    reader = %{
      size: parse_meta(meta, 'SZ'),
      counting_rules: parse_meta(meta, 'BC'),
      black: parse_meta(meta, 'PB'),
      black_rank: parse_meta(meta, 'BR'),
      white: parse_meta(meta, 'PW'),
      white_rank: parse_meta(meta, 'WR'),
      komi: parse_meta(meta, 'KM'),
      date: parse_meta(meta, 'DT'),
      result: parse_meta(meta, 'RE'),
      moves: parse_moves(sgf),
      move_index: -1,
      game: %{}
    }

    reset_game(reader)
  end

  def seek(reader, index) do
    cond do
      index < 0 ->
        Printer.puts("Already at first move!")
        reset_game(reader)

      index >= length(reader[:moves]) ->
        Printer.puts("Already at last move!")
        seek(reader, length(reader[:moves]) - 1)

      index == reader[:move_index] ->
        reader

      true ->
        {game, next_index} =
          if index > reader[:move_index] do
            next_index = reader[:move_index] + 1
            move_str = Enum.at(reader[:moves], next_index)
            {type, move} = parse_move(move_str)

            game =
              if type == :pass do
                {color} = move
                Game.pass(reader[:game], color)
              else
                {color, y, x} = move
                Game.play(reader[:game], color, {y, x})
              end

            {game, next_index}
          else
            {Game.undo(reader[:game]), reader[:move_index] - 1}
          end

        reader = Map.put(reader, :game, game)
        reader = Map.put(reader, :move_index, next_index)
        seek(reader, index)
    end
  end

  def next(reader) do
    seek(reader, reader[:move_index] + 1)
  end

  def previous(reader) do
    seek(reader, reader[:move_index] - 1)
  end

  def print(reader) do
    Game.print(reader[:game])
  end

  defp reset_game(reader) do
    size = String.to_integer(reader[:size])
    game = Game.new(size)
    game = Game.update_player(game, :black, "#{reader[:black]} [#{reader[:black_rank]}]")
    game = Game.update_player(game, :white, "#{reader[:white]} [#{reader[:white_rank]}]")

    reader = Map.put(reader, :move_index, -1)
    Map.put(reader, :game, game)
  end

  defp parse_meta(sgf) do
    Enum.at(String.split(sgf, ";"), 1)
  end

  defp parse_meta(meta, key) do
    matcher = Regex.compile!("#{key}\\[(.*?)\\]")
    match = Regex.run(matcher, meta)

    if match do
      Enum.at(match, 1)
    else
      ""
    end
  end

  defp parse_moves(sgf) do
    Enum.drop(String.split(sgf, ";"), 2)
  end

  defp parse_move(move) do
    match = Regex.named_captures(@move_regex, move)

    pass_move = {:pass, {to_color(match["color"])}}

    if match do
      if match["row"] == "t" && match["col"] == "t" do
        pass_move
      else
        {:play,
         {to_color(match["color"]), letter_to_integer(match["row"]),
          letter_to_integer(match["col"])}}
      end
    else
      pass_move
    end
  end

  defp letter_to_integer(row) do
    Enum.at(String.to_charlist(row), 0) - ?a
  end

  defp to_color(color) do
    if color == "B" do
      :black
    else
      :white
    end
  end
end
