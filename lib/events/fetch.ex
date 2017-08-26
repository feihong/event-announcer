defmodule Mix.Tasks.Events.Fetch do
  use Mix.Task

  @shortdoc "Fetch events and generate a report"

  def run(_args) do
    Application.ensure_all_started :httpoison
    Application.ensure_all_started :timex_ecto
    Mix.Ecto.ensure_started Events.Repo, []

    events = Events.Facebook.fetch_all()
      |> Enum.filter(&not_read/1)
      |> Enum.sort_by(&sort_mapper/1)

    # Get the number of events that matched keywords.
    match_count = events
      |> Enum.count(fn evt -> length(evt.matched_keywords) > 0 end)

    events |> Events.Util.to_json_file("events.json")

    template = "templates/report.slime" |> File.read!
    Slime.render(template, events: events, match_count: match_count)
      |> (fn output -> File.write("report.html", output) end).()

    IO.puts "\nWrote #{length(events)} events to report.html and events.json"
  end

  defp not_read(evt) do
    result = Events.ReadItem
      |> Events.Repo.get_by(source: evt.source, source_id: evt.source_id)
    result == nil
  end

  defp sort_mapper(evt) do
    # Make sure that events that match keywords are always in front
    # regardless of start time.
    num = if length(evt.matched_keywords) > 0, do: 0, else: 1
    {num, evt.timestamp}
  end
end
