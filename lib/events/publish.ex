defmodule Mix.Tasks.Events.Publish do
  use Mix.Task

  @shortdoc "Publish events to a meetup group"
  @api_key Application.fetch_env!(:events, Meetup)[:api_key]
  @urlname Application.fetch_env!(:events, Meetup)[:urlname]

  def run(args) do
    Application.ensure_all_started :httpoison

    indexes = args |> Enum.map(&String.to_integer/1)

    Events.Util.from_json_file("events.json")
      |> Enum.with_index(1)
      |> Enum.filter(fn {_evt, index} -> index in indexes end)
      |> Enum.map(fn {evt, _index} -> evt end)
      |> Enum.map(&publish/1)
  end

  defp publish(evt) do
    url = "https://api.meetup.com/#{@urlname}/events"
    desc = "#{evt.description}\n\nSource: #{evt.url}"
    full_desc = if evt.is_series do
      "#{desc}\n\nNote: This event is part of a series. You may be able to attend it on other dates and times."
    else
      desc
    end

    params = %{
      key: @api_key,
      name: evt.name,
      description: full_desc,
      publish_status: "draft",
      time: evt.timestamp * 1000,
      duration: evt.duration * 1000,
      event_hosts: "",
      self_rsvp: "false"
    }
    res = HTTPoison.post!(url, [], [], params: params)
    if res.status_code == 201 do
      IO.puts "Posted #{evt.name} at #{evt.venue}"
    end
  end
end
