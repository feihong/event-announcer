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
      |> Enum.map(fn m -> Map.put(m, "organization", name) end)
  end

  defp convert(evt_map) do
    # Meetup description field HATES spaces before newlines.
    desc =
      evt_map
      |> Map.get("description", "")
      |> String.replace(" \n", "\n")
    start_time = Timex.parse!(evt_map["start_time"], "{ISO:Extended}")
    end_time =
      case Timex.parse(evt_map["end_time"], "{ISO:Extended}") do
        {:ok, val} -> val
        {:error, _reason} -> nil
      end
    location = evt_map["place"]["location"]
    address = ["street", "city", "zip"]
      |> Enum.map(fn key -> location[key] end)
      |> Enum.join(", ")
    duration =
      if end_time != nil do
        Timex.diff(end_time, start_time, :seconds)
      else
        0
      end

    %Events.Event{
      source: "facebook",
      organization: evt_map["organization"],
      source_id: evt_map["id"],
      name: evt_map["name"],
      description: desc,
      url: "https://facebook.com/events/#{evt_map["id"]}",
      venue: evt_map["place"]["name"],
      address: address,
      start_time: start_time,
      timestamp: Timex.to_unix(start_time),
      duration: duration,
    }
  end
end
