defmodule Main do
  alias Events.Download

  def main() do
    url = "http://www.chicagofilmfestival.com/festival/film-event-listing/"
    html = Download.fetch_page("chifilmfest__index", url, %{})
    film_urls =
      Floki.find(html, "ul.film-list li a")
      |> Floki.attribute("href")
      |> Enum.filter(fn url -> not String.contains?(url, "/special-architecture/") end)

    events =
      film_urls
      |> Enum.map(&download_film_page/1)
      |> Enum.take(1)
      |> Enum.map(&convert/1)

    IO.puts "Found #{length(film_urls)} films"

    IO.puts List.first(events)[:description]
  end

  def download_film_page(url) do
    slug = String.split(url, "/", trim: true)
    |> List.last()
    Download.fetch_page("chifilmfest__#{slug}", url, %{})
  end

  def convert(html) do
    main = Floki.find(html, "section#main")
    title = main |> Floki.find("h1") |> Floki.text
    meta =
      Floki.find(main, ".film-credits li")
      |> Enum.map(fn li ->
          label = Floki.find(li, "label") |> Floki.text
          value = Floki.filter_out(li, "label") |> Floki.text |> String.trim
          "#{label}: #{value}"
         end)
      |> Enum.join("\n")

    synopsis = Floki.find(main, ".film-synopsis") |> Floki.text
    %{
      name: title,
      description: meta,
    }
  end
end


Main.main()
