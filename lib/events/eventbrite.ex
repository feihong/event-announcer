defmodule Events.EventBrite do
  @keywords Application.fetch_env!(:events, :keywords)
  @base_url "https://www.eventbriteapi.com/v3"
  @access_token Application.fetch_env!(:events, EventBrite)[:access_token]
  @location Application.fetch_env!(:events, EventBrite)[:location]

  @doc """
  Fetch EventBrite events as a list of Event structs.
  """
  def fetch_all() do
    max_concurrency = System.schedulers_online() * 2

    @keywords
      |> Task.async_stream(fn keyword -> fetch(keyword) end,
            ordered: false, max_concurrency: max_concurrency)
      |> Enum.flat_map(fn {:ok, events} -> events end)
      |> Enum.uniq_by(fn evt -> evt["id"] end)
      |> Enum.map(&convert/1)
      |> Enum.map(fn evt -> Events.Util.match_keywords(evt, @keywords) end)
  end

  defp fetch(keyword) do
    url = "#{@base_url}/events/search/"
    params = %{
      token: @access_token,
      q: keyword,
      sort_by: "date",
      "location.address": @location
    }
    data = Events.Download.fetch("eventbrite__#{keyword}", url, params)
    # pagination = data["pagination"]
    data["events"]
      |> Enum.map(&download_venue/1)
  end

  defp download_venue(evt_map) do
    venue_id = evt_map["venue_id"]
    url = "#{@base_url}/venues/#{venue_id}/"
    params = %{token: @access_token}
    venue = Events.Download.fetch("eventbrite__venue__#{venue_id}", url, params)
    evt_map |> Map.put("venue", venue)
  end

  defp convert(evt_map) do
    start_time = convert_datetime_map(evt_map["start"])
    end_time = convert_datetime_map(evt_map["end"])

    %Events.Event{
      source: "eventbrite",
      source_id: evt_map["id"],
      name: evt_map["name"]["text"],
      description: evt_map["description"]["text"],
      url: evt_map["url"],
      venue: evt_map["venue"]["name"],
      start_time: start_time,
      timestamp: Timex.to_unix(start_time),
      duration: Timex.diff(end_time, start_time, :seconds)
    }
  end

  defp convert_datetime_map(map) do
    naive_dt = Timex.parse!(map["local"], "{ISO:Extended}")
    Timex.to_datetime(naive_dt, map["timezone"])
  end
end
