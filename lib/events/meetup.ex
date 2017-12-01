require Logger


defmodule Events.Meetup do
  use GenServer

  @api_key Application.fetch_env!(:events, Meetup)[:api_key]
  @urlname Application.fetch_env!(:events, Meetup)[:urlname]
  @series_text "Note: This event is part of a series. You may be able to attend it on other dates and times."
  @max_duration 12 * 3600   # 12 hours

  @doc """
  Publish the given event to Meetup.com.
  """
  def publish(evt) do
    GenServer.call(__MODULE__, evt)
  end

  def start_link() do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def handle_call(evt, _from, venue_map) do
    if String.length(evt.name) > 80 do
      Logger.warn "Event \"#{evt.name}\" has a name longer than 80 characters"
    end

    {venue_id, new_venue_map} = get_venue_id(evt, venue_map)

    url = "https://api.meetup.com/#{@urlname}/events"
    params =
      get_params(evt)
      |> add_venue_id(venue_id)
      |> add_time(evt.start_time)

    result = HTTPoison.post(url, [], [], params: params)
    case result do
        {:ok, res} ->
          if res.status_code == 201 do
            Logger.info "Posted #{evt.name} at #{evt.venue}"
          else
            Logger.error "Status code #{res.status_code}, response: #{res.body}"
          end
        {:error, reason} ->
            Logger.error "Error: #{reason}"
    end
    {:reply, result, new_venue_map}
  end

  defp get_params(evt) do
    desc = [
      "Source: #{evt.url}",
      (if evt.is_series, do: @series_text),
      evt.description,
    ]
    |> Enum.filter(&(&1 != nil))
    |> Enum.join("\n\n")

    [
      key: @api_key,
      name: String.slice(evt.name, 0..79),
      description: desc,
      publish_status: "draft",
      event_hosts: "",
      self_rsvp: "false"
    ]
    |> add_duration(evt.duration)
  end

  defp get_venue_id(evt, venue_map) do
    if evt.venue == nil do
      {:doesnotexist, venue_map}
    else
      key = {evt.venue, evt.address}
      case Map.fetch(venue_map, key) do
        {:ok, val} -> {val, venue_map}
        _ ->
          result = find_venue(key)
          {result, venue_map |> Map.put(key, result)}
      end
    end
  end

  defp find_venue({name, address}) do
    url = "https://api.meetup.com/find/venues"
    params = [key: @api_key, text: name, location: address]
    matches =
      HTTPoison.get!(url, [], params: params)
      |> Map.fetch!(:body)
      |> Poison.decode!
      |> Enum.filter(&(&1["name"] == name))
      |> Enum.sort_by(&(&1["rating_count"]), &>=/2)

    if length(matches) == 0 do
      :doesnotexist
    else
      IO.puts "Found venue for #{name} at #{address}"
      List.first(matches)["id"]
    end
  end

  defp add_time(params, start_time) do
    timestamp = start_time |> Timex.to_unix
    # Convert to milliseconds.
    params ++ [time: timestamp * 1000]
  end

  defp add_duration(params, duration) do
    # If duration is excessively long, it's most likely a multi-day event. If
    # duration is zero, then it's likely unknown. In either case, leave it out.
    if duration > @max_duration or duration == 0 do
      params
    else
      # Multipy by 100 to get duration in milliseconds.
      params ++ [duration: round_duration(duration) * 1000]
    end
  end

  defp add_venue_id(params, venue_id) do
    case venue_id do
      :doesnotexist -> params
      val -> params ++ [venue_id: val]
    end
  end

  defp round_duration(n) do
    # Round duration up to closest 15 minutes (900 seconds).
    if rem(n, 900) == 0 do
      n
    else
      round_duration(n + 1)
    end
  end
end
