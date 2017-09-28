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
      |> Enum.map(fn url -> {url, download_film_page(url)} end)
      |> Enum.take(1)
      |> Enum.map(&convert/1)

    IO.puts "Found #{length(film_urls)} films"

    evt = List.first(events)
    IO.puts evt[:description]
    IO.puts evt[:duration]
    IO.inspect evt[:screenings]
  end

  def download_film_page(url) do
    slug = String.split(url, "/", trim: true)
    |> List.last()
    Download.fetch_page("chifilmfest__#{slug}", url, %{})
  end

  defp convert({url, html}) do
    main = Floki.find(html, "section#main")
    title = main |> Floki.find("h1") |> Floki.text
    meta =
      Floki.find(main, ".film-credits li")
      |> Enum.map(fn li ->
          label = Floki.find(li, "label") |> Floki.text
          value = Floki.filter_out(li, "label") |> Floki.text |> String.trim
          {label, value}
         end)

    duration =
      meta
      |> Enum.find(fn {label, _value} -> label == "Run Time" end)
      |> elem(1)
      |> String.trim_trailing(" minutes")
      |> String.to_integer
      |> (fn n -> n * 60 end).()

    meta_string =
      meta
      |> Enum.map(fn {label, value} -> "#{label}: #{value}" end)
      |> Enum.join("\n")

    synopsis =
      Floki.find(main, ".film-synopsis p")
      |> Enum.map(&Floki.text/1)
      |> Enum.join("\n\n")

    [{_tag, _attrs, children}] = Floki.find(main, ".film-screening-info")
    screenings =
      children
      |> Enum.filter(&is_binary/1)
      |> Enum.map(fn s ->
          Timex.parse!(s, "{WDshort}, {Mshort} {D}, {YYYY} {h12}:{m} {AM}") end)

    %{
      source: "chicagofilmfestival",
      name: title,
      description: Enum.join([meta_string, synopsis], "\n\n"),
      url: url,
      venue: "AMC River East 21",
      address: "322 E Illinois St, Chicago, IL 60611",
      duration: duration,
      screenings: screenings
    }
  end

  # Turn one event into multiple
  defp expand(event) do
    []
  end
end


Main.main()
