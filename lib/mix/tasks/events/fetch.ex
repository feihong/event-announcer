defmodule Mix.Tasks.Events.Fetch do
  use Mix.Task

  @shortdoc "Fetch events and generate a report"

  def run(_args) do
    Application.ensure_all_started :httpoison
    Application.ensure_all_started :timex
    Mix.Ecto.ensure_started Events.Repo, []
    Events.Fetcher.start_link()

    events = Events.Fetcher.fetch()
    events |> Events.Util.to_json_file("events.json")

    # Get the number of events that matched keywords.
    match_count = events
      |> Enum.count(fn evt -> length(evt.matched_keywords) > 0 end)

    template = "templates/report.slime" |> File.read!
    Slime.render(template, events: events, match_count: match_count)
      |> (fn output -> File.write("report.html", output) end).()

    IO.puts "\nWrote #{length(events)} events to report.html and events.json"
  end
end
