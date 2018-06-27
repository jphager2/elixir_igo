Application.ensure_all_started(:inets)
Application.ensure_all_started(:ssl)

defmodule Http do
  def get(url) do
    {:ok, {{'HTTP/1.1', 200, 'OK'}, _headers, body}} =
      :httpc.request(:get, {url, []}, [], [])

    :erlang.iolist_to_binary(body)
  end
end

defmodule Html do
  require Record
  Record.defrecord :xmlElement, Record.extract(:xmlElement, from_lib: "xmerl/include/xmerl.hrl")
  Record.defrecord :xmlText,    Record.extract(:xmlText,    from_lib: "xmerl/include/xmerl.hrl")

  @html_gotchas ~r{(<(br|img)[^>]*>|&.+?;)}

  def parse(string) do
    { doc, [] } = string
                  |> String.replace(@html_gotchas, " ")
                  |> :erlang.binary_to_list
                  |> :xmerl_scan.string

    doc
  end

  def xpath(doc, path) do
    elements = :xmerl_xpath.string(path, doc)
    Enum.map(elements, fn(element) ->
      xmlElement(element, :content)
    end)
  end

  def text_at_xpath(doc, path) do
    text = Enum.map(xpath(path, doc), fn(content) ->
      xmlText(content, :value)
    end)

    Enum.join(text, ' ')
  end
end

html = Http.get('http://gokifu.com')

Html.parse(html)
  |> Html.xpath('//*[@id="gamelist"]/div[@class="cblock_3"]/div[@class="game_type"]/a[2]')
  |> IO.inspect
