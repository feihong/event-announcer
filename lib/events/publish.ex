require Logger


defmodule Mix.Tasks.Events.Publish do
  @shortdoc "Publish events to a meetup group"
  use Mix.Task

  def run(args) do
    Application.ensure_all_started :httpoison
    Events.Meetup.start_link([])

    indexes = args |> Enum.map(&String.to_integer/1)

    Events.Util.from_json_file("events.json")
    |> Enum.with_index(1)
    |> Enum.filter(fn {_evt, index} -> index in indexes end)
    |> Enum.map(fn {evt, _index} -> evt end)
    |> Enum.map(&Events.Meetup.publish/1)
  end
end
