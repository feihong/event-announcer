defmodule Mix.Tasks.Events.MarkRead do
  use Mix.Task

  @shortdoc "Mark events in the report as read"

  def run(_args) do
    if File.exists?("report.json") do
      Events.Util.from_json_file("report.json")
        |> Enum.filter(fn evt -> length(evt["matched_keywords"]) == 0 end)
        |> Enum.map(&add_read_item/1)
    else
      IO.puts "The report.json file was not found"
    end
  end

  defp add_read_item(evt) do
    IO.puts evt["name"]
  end
end
