alias Igo.Printer, as: Printer

defmodule Igo.Player do
  def print(player) do
    Printer.print(Enum.join([player[:name], "(", player[:captures], ")"]))
  end
end
