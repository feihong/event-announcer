defmodule Main do
  alias Events.Download

  def main() do
    url = "http://www.chicagofilmfestival.com/festival/film-event-listing/"
    html = Download.fetch_page("chifilmfest__index", url, %{})
    film_urls =
      Floki.find(html, "ul.film-list li a")
      |> Floki.attribute("href")
      |> Enum.filter(fn url -> not String.contains?(url, "/special-architecture/") end)

    film_urls
    |> Enum.map(&download_film_page/1)

    IO.puts "Found #{length(film_urls)} films"
  end

  def download_film_page(url) do
    slug = String.split(url, "/", trim: true)
    |> List.last()
    Download.fetch_page("chifilmfest__#{slug}", url, %{})
  end
end


Main.main()
