defmodule Mix.Tasks.Events.Fetch do
  use Mix.Task

  @shortdoc "Fetch events and generate a report"
  @keywords Application.fetch_env!(:events, :keywords)
  @access_token Application.fetch_env!(:events, Facebook)[:access_token]

  def run(_args) do
    IO.inspect Application.ensure_all_started :httpoison

    events = fetch_all()
    # Get the number of events that matched keywords.
    match_count = events
      |> Enum.count(fn evt -> length(evt["matched_keywords"]) > 0 end)

    events
      |> Poison.encode!(pretty: true)
      |> (fn text -> File.write!("report.json", text) end).()

    template = "templates/report.slime" |> File.read!
    Slime.render(template, events: events, match_count: match_count)
      |> (fn output -> File.write("report.html", output) end).()

    IO.puts "Wrote events to report.html"
  end

  defp fetch_all() do
    page_names = Application.fetch_env!(:events, Facebook)[:pages]

    # Fetch all events and sort.
    page_names
      |> Enum.map(fn name -> fetch(name) end)
      |> List.flatten
      |> Enum.map(&enhance/1)
      |> Enum.sort_by(&sort_mapper/1)
  end

  defp fetch(name) do
    alias Events.Download

    cache_name = "facebook__#{name}"
    url = "https://graph.facebook.com/v2.9/#{name}/events/"
    params = %{access_token: @access_token,
               since: DateTime.utc_now |> DateTime.to_iso8601}

    Download.fetch(cache_name, url, params)["data"]
  end

  defp enhance(evt) do
    text = evt["name"] <> "  " <> evt["description"] |> String.downcase
    matched_keywords =
      for keyword <- @keywords,
          String.contains?(text, keyword) do
        keyword
      end

    evt
      |> Map.put("url", "https://facebook.com/events/#{evt["id"]}")
      |> Map.put("matched_keywords", matched_keywords)
      |> Map.put("start_dt", Timex.parse!(evt["start_time"], "{ISO:Extended}"))
  end

  defp sort_mapper(evt) do
    # Make sure that events that match keywords are always in front
    # regardless of start time.
    num = if length(evt["matched_keywords"]) > 0, do: 0, else: 1
    {num, evt["start_time"]}
  end
end
