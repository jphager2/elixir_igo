alias Igo.SgfReader, as: SgfReader
alias Igo.Printer, as: Printer

defmodule Igo.CLI do
  def main(args \\ []) do
    { subcommand, args } = List.pop_at(args, 0)

    cond do
      subcommand == "play" ->
        Igo.play()

      subcommand == "gokifu" ->
        Igo.gokifu()

      subcommand == "review" ->
        review(args)

      true ->
        Printer.puts("Unknown command.")
    end
  end

  defp review(args) do
    if length(args) > 0 do
      file = Enum.at(args, 0)
      reader = SgfReader.new(file)
      Igo.review(reader)
    else
      Igo.review()
    end
  end
end
