defmodule Mix.Tasks.Events.Fetch do
  use Mix.Task

  @shortdoc "Fetch events and generate a report"
  @keywords Application.fetch_env!(:events, :keywords)
  @access_token Application.fetch_env!(:events, Facebook)[:access_token]

  def run(_args) do
    Application.ensure_all_started :httpoison
    Application.ensure_all_started :timex_ecto
    Mix.Ecto.ensure_started Events.Repo, []

    events = fetch_all()
    # Get the number of events that matched keywords.
    match_count = events
      |> Enum.count(fn evt -> length(evt.matched_keywords) > 0 end)

    events |> Events.Util.to_json_file("events.json")

    template = "templates/report.slime" |> File.read!
    Slime.render(template, events: events, match_count: match_count)
      |> (fn output -> File.write("report.html", output) end).()

    IO.puts "\nWrote #{length(events)} events to report.html and events.json"
  end

  defp fetch_all() do
    page_names = Application.fetch_env!(:events, Facebook)[:pages]
    max_concurrency = System.schedulers_online() * 2

    # Fetch all events and sort.
    page_names
      |> Task.async_stream(fn name -> fetch(name) end,
            ordered: false, max_concurrency: max_concurrency)
      |> Enum.reduce([], fn({:ok, events}, acc) -> acc ++ events end)
      |> Enum.filter(&not_read/1)
      |> Enum.map(&convert/1)
      |> Enum.sort_by(&sort_mapper/1)
  end

  defp fetch(name) do
    # Returns a list of maps.
    cache_name = "facebook__#{name}"
    url = "https://graph.facebook.com/v2.9/#{name}/events/"
    params = %{access_token: @access_token,
               since: DateTime.utc_now |> DateTime.to_iso8601}

    Events.Download.fetch(cache_name, url, params)["data"]
  end

  defp not_read(evt_map) do
    result = Events.ReadItem
      |> Events.Repo.get_by(source: "facebook", source_id: evt_map["id"])
    result == nil
  end

  defp convert(evt_map) do
    start_time = Timex.parse!(evt_map["start_time"], "{ISO:Extended}")
    end_time = Timex.parse!(evt_map["end_time"], "{ISO:Extended}")

    evt = %Events.Event{
      source: "facebook",
      source_id: evt_map["id"],
      name: evt_map["name"],
      description: evt_map["description"],
      url: "https://facebook.com/events/#{evt_map["id"]}",
      venue: evt_map["place"]["name"],
      start_time: start_time,
      timestamp: Timex.to_unix(start_time),
      duration: Timex.diff(end_time, start_time, :seconds)
    }

    text = evt.name <> "  " <> evt.description |> String.downcase
    matched_keywords =
      for keyword <- @keywords, String.contains?(text, keyword) do
        keyword
      end

    %{evt | matched_keywords: matched_keywords}
  end

  defp sort_mapper(evt) do
    # Make sure that events that match keywords are always in front
    # regardless of start time.
    num = if length(evt.matched_keywords) > 0, do: 0, else: 1
    {num, evt.timestamp}
  end
end
