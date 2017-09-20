require Logger


defmodule Mix.Tasks.Events.Publish do
  use Mix.Task

  @shortdoc "Publish events to a meetup group"
  @api_key Application.fetch_env!(:events, Meetup)[:api_key]
  @urlname Application.fetch_env!(:events, Meetup)[:urlname]
  @series_text "Note: This event is part of a series. You may be able to attend it on other dates and times."

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
    desc = [
      "Source: #{evt.url}",
      (if evt.is_series, do: @series_text),
      evt.description,
    ] |> Enum.filter(fn s -> s != nil end)
      |> Enum.join("\n\n")

    if String.length(evt.name) > 80 do
      Logger.warn "Event \"#{evt.name}\" has a name longer than 80 characters"
    end

    params = %{
      key: @api_key,
      name: String.slice(evt.name, 0..79),
      description: desc,
      publish_status: "draft",
      time: evt.timestamp * 1000,
      duration: evt.duration * 1000,
      event_hosts: "",
      self_rsvp: "false"
    }
    res = HTTPoison.post!(url, [], [], params: params)
    if res.status_code == 201 do
      IO.puts "Posted #{evt.name} at #{evt.venue}"
    else
      Logger.error "Status code #{res.status_code}, response: #{res.body}"
    end
  end
end
