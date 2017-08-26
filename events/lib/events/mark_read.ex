defmodule Mix.Tasks.Events.MarkRead do
  use Mix.Task

  @shortdoc "Mark events in the report as read"

  def run(_args) do
    Application.ensure_all_started :timex_ecto
    Mix.Ecto.ensure_started Events.Repo, []

    if File.exists?("events.json") do
      Events.Util.from_json_file("events.json")
        |> Enum.filter(fn evt -> length(evt.matched_keywords) == 0 end)
        |> Enum.map(&insert_read_item/1)
        |> IO.inspect
    else
      IO.puts "The events.json file was not found"
    end
  end

  defp insert_read_item(evt) do
    %Events.ReadItem{
      source: evt.source,
      source_id: evt.source_id,
      name: evt.name,
      start_time: evt.start_time
    } |> Events.Repo.insert
  end
end
