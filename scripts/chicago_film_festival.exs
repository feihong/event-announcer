defmodule Main do
  alias Events.Download

  @screening_format "{WDshort}, {Mshort} {D}, {YYYY} {h12}:{m} {AM}"

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
    # Get list of metadata tuples.
    meta =
      Floki.find(main, ".film-credits li")
      |> Enum.map(fn li ->
          label = Floki.find(li, "label") |> Floki.text
          value = Floki.filter_out(li, "label") |> Floki.text |> String.trim
          {label, value}
         end)

    meta_string =
      meta
      |> Enum.map(fn {label, value} -> "#{label}: #{value}" end)
      |> Enum.join("\n")

    synopsis =
      Floki.find(main, ".film-synopsis p")
      |> Enum.map(&Floki.text/1)
      |> Enum.join("\n\n")

    event = %Events.Event{
      source: "chicagofilmfestival",
      name: title,
      description: Enum.join([synopsis, meta_string], "\n\n"),
      url: url,
      venue: "AMC River East 21",
      address: "322 E Illinois St, Chicago, IL 60611",
      duration: get_duration(meta),
    }
    {event, get_screenings(main)}
  end

  defp get_screenings(main) do
    [{_tag, _attrs, children}] = Floki.find(main, ".film-screening-info")
    screening_lines =
      children
      |> Enum.filter(&is_binary/1)
      |> Enum.filter(fn s ->
          Regex.match? ~r/^Mon|Tue|Wed|Thu|Fri|Sat|Sun/, s end)

    screenings =
      screening_lines
      |> Enum.map(fn s ->
          case Timex.parse(s, @screening_format) do
            {:ok, dt} -> dt
            _ -> nil
          end
        end)
      |> Enum.filter(fn v -> v != nil end)

    screenings
  end

  defp get_duration(meta) do
    run_time =
      meta
      |> Enum.find(fn {label, _value} -> label == "Run Time" end)
      |> (fn result ->
            case result do
              {_label, value} -> value
              _ -> nil
            end
          end).()

    if run_time == nil do
      0
    else
      run_time
      |> String.trim_trailing(" minutes")
      |> String.to_integer
      |> (fn n -> n * 60 end).()
    end
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
