defmodule Mix.Tasks.Events.MarkRead do
  use Mix.Task

  @shortdoc "Mark all events in the report as read"

  def run(_args) do
    if File.exists?("report.json") do
      IO.puts "Process report.json..."
    else
      IO.puts "The report.json file was not found"
    end
  end
end
