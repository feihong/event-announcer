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
      # |> Enum.take(1)
      |> Enum.map(&convert/1)
      |> Enum.map(&expand/1)
      |> Enum.concat

    IO.puts "Found #{length(film_urls)} films and #{length(events)} events\n"

    evt = List.first(events)
    IO.puts evt.description
    IO.puts evt.start_time
  end

  def download_film_page(url) do
    slug = String.split(url, "/", trim: true)
    |> List.last()
    Download.fetch_page("chifilmfest__#{slug}", url, %{})
  end

  defp convert({url, html}) do
    IO.puts url
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

    event = %Events.Event{
      source: "chicagofilmfestival",
      name: title,
      description: Enum.join([synopsis, meta_string], "\n\n"),
      url: url,
      venue: "AMC River East 21",
      address: "322 E Illinois St, Chicago, IL 60611",
      duration: duration,
    }
    {event, screenings}
  end

  # Return an Event struct for each screening.
  defp expand({event, screenings}) do
    screenings
    |> Enum.map(fn screening ->
        %{event | start_time: screening,
                  timestamp: Timex.to_unix(screening)} end)
  end
end


Main.main()
