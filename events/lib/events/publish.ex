defmodule Mix.Tasks.Events.Publish do
  use Mix.Task

  @shortdoc "Publish events to a meetup group"
  @api_key Application.fetch_env!(:events, Meetup)[:api_key]
  @urlname Application.fetch_env!(:events, Meetup)[:urlname]

  def run(args) do
    indexes = args |> Enum.map(&String.to_integer/1)

    for index <- indexes do
      IO.puts index
    end
  end
end
