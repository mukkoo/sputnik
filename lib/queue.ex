defmodule Queue do

  def start(url) do
    spawn __MODULE__, :loop, [url]
  end

  def loop(url) do
    Page.start(url, self())
    %URI{host: host} = URI.parse(url)
    loop(host, [url],[])
  end

  defp loop(domain, [], done) do
    IO.puts ""
    IO.puts "done #: #{Enum.count(done)}"
  end

  defp loop(domain, processing, done) do
    receive do
      {:ok, status_code, request_url, links} ->
        {processing, done} = set_as_done(request_url, processing, done, status_code)
        {processing} = enqueue(links, processing, done, domain)
        IO.write "."
        loop(domain, processing, done)
    end
  end

  defp set_as_done(request_url, processing, done, status_code) do
    done = done ++ [{status_code, request_url}]
    processing = processing -- [request_url]
    {processing, done}
  end

  defp enqueue(links, processing, done, domain) do
    parsed_done = Enum.map(done, fn({status, url}) -> url end)
    filtered_links = Enum.filter(links, (fn(link) -> same_domain(link, domain) end))
                      |> Enum.filter(fn(link) -> !Enum.member?(processing, link) end)
                      |> Enum.filter(fn(link) -> !Enum.member?(parsed_done, link) end)
    Enum.each filtered_links, (fn(link) -> Page.start(link, self()) end)
    processing = processing ++ filtered_links
    {processing}
  end

  defp same_domain(link, domain) do
    %URI{host: host} = URI.parse(link)
    host == domain
  end
end