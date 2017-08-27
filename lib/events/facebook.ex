defmodule Events.Facebook do
  @keywords Application.fetch_env!(:events, :keywords)
  @access_token Application.fetch_env!(:events, Facebook)[:access_token]

  @doc """
  Fetch all Facebook events as a list of Event structs.
  """
  def fetch_all() do
    page_names = Application.fetch_env!(:events, Facebook)[:pages]
    max_concurrency = System.schedulers_online() * 2

    # Fetch all events and sort.
    page_names
      |> Task.async_stream(fn name -> fetch(name) end,
            ordered: false, max_concurrency: max_concurrency)
      |> Enum.flat_map(fn {:ok, events} -> events end)
      |> Enum.map(&convert/1)
      |> Enum.map(fn evt -> Events.Util.match_keywords(evt, @keywords) end)
  end

  defp fetch(name) do
    # Returns a list of maps.
    cache_name = "facebook__#{name}"
    url = "https://graph.facebook.com/v2.9/#{name}/events/"
    params = %{access_token: @access_token,
               since: DateTime.utc_now |> DateTime.to_iso8601}

    Events.Download.fetch(cache_name, url, params)["data"]
  end

  defp convert(evt_map) do
    start_time = Timex.parse!(evt_map["start_time"], "{ISO:Extended}")
    end_time = Timex.parse!(evt_map["end_time"], "{ISO:Extended}")

    %Events.Event{
      source: "facebook",
      source_id: evt_map["id"],
      name: evt_map["name"],
      description: evt_map["description"],
      url: "https://facebook.com/events/#{evt_map["id"]}",
      venue: evt_map["place"]["name"],
      start_time: start_time,
      timestamp: Timex.to_unix(start_time),
      duration: Timex.diff(end_time, start_time, :seconds)
    }
  end
end
