defmodule Mix.Tasks.Events.MarkRead do
  use Mix.Task

  @shortdoc "Mark events in the report as read"

  def run(args) do
    Application.ensure_all_started :timex
    Mix.Ecto.ensure_started Events.Repo, []

    if File.exists?("events.json") do
      results = Events.Util.from_json_file("events.json")

      events =
        if args == ["all"] do
          results
        else
          results
            |> Enum.filter(fn evt -> length(evt.matched_keywords) == 0 end)
        end

      events |> Enum.map(&insert_read_item/1)

      IO.puts "Marked #{length(events)} events as read"
    else
      IO.puts "The events.json file was not found"
    end
  end

  defp insert_read_item(evt) do
    evt
    |> Map.from_struct
    |> Events.ReadItem.changeset
    |> Events.Repo.insert
  end
end
