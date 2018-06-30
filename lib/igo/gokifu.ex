Application.ensure_all_started(:inets)
Application.ensure_all_started(:ssl)

defmodule Igo.GoKifu do
  def get_games do
    html = get('http://gokifu.com')

    games =
      html
      |> Floki.find(".player_block.cblock_3")
      |> Enum.map(fn game -> build_game(game) end)

    games
  end

  def download_game(game) do
    url = elem(game, 4)

    sgf = get(String.to_charlist(url))
    File.write!(download_path(game), sgf)
  end

  def download_path(game) do
    url = elem(game, 4)
    filename = Enum.at(String.split(url, "/"), -1)

    "/home/john/Downloads/#{filename}"
  end

  defp build_game(tag) do
    [black, white] =
      tag
      |> Floki.find(".player_name a")
      |> Enum.map(fn player -> Floki.text(player) end)

    [[url]] =
      tag
      |> Floki.find(".game_type a:nth-of-type(2)")
      |> Enum.map(fn link -> Floki.attribute(link, "href") end)

    date =
      Floki.find(tag, ".game_date")
      |> Floki.text()

    result =
      Floki.find(tag, ".game_result")
      |> Floki.text()

    {black, white, date, result, url}
  end

  defp get(url) do
    {:ok, {{'HTTP/1.1', 200, 'OK'}, _headers, body}} = :httpc.request(:get, {url, []}, [], [])

    :erlang.iolist_to_binary(body)
  end
end
