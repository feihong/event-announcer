require Logger


defmodule Events.Meetup do
  @api_key Application.fetch_env!(:events, Meetup)[:api_key]
  @urlname Application.fetch_env!(:events, Meetup)[:urlname]
  @series_text "Note: This event is part of a series. You may be able to attend it on other dates and times."
  @twelve_hours 12 * 3600

  use GenServer

  def publish(evt) do
    GenServer.call(__MODULE__, evt)
  end

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @doc """
  Publish the given event to Meetup.com.
  """
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
    res = HTTPoison.post!(url, [], [], params: params)
    if res.status_code == 201 do
      IO.puts "Posted #{evt.name} at #{evt.venue}"
    else
      Logger.error "Status code #{res.status_code}, response: #{res.body}"
    end
    {:reply, :ok, new_venue_map}
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
    key = {evt.venue, evt.address}
    case Map.fetch(venue_map, key) do
      {:ok, val} -> {val, venue_map}
      _ ->
        result = find_venue(key)
        {result, Map.put(venue_map, key, result)}
    end
  end

  defp find_venue({name, address}) do
    IO.puts "Find venue matching #{name} with address #{address}"
    url = "https://api.meetup.com/find/venues"
    params = [key: @api_key, text: name, location: address]
    matches =
      HTTPoison.get!(url, [], params: params)
      |> (fn response -> response.body end).()
      |> Poison.decode!
      |> Enum.filter(&(&1["name"] == name))
      |> Enum.sort_by(&(&1["rating_count"]), &>=/2)

    if length(matches) == 0 do
      :doesnotexist
    else
      List.first(matches)["id"]
    end
  end

  defp add_time(params, start_time) do
    # When venue_id is specified, then you have to use UTC.
    timestamp =
      if params[:venue_id] == nil do
        start_time |> Timex.to_unix
      else
        start_time |> Timex.shift(hours: +5) |> Timex.to_unix
      end

    # Convert to milliseconds.
    params ++ [time: timestamp * 1000]
  end

  defp add_duration(params, duration) do
    # If duration is excessively long, it's most likely a multi-day event, so
    # leave it out.
    if duration > @twelve_hours do
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
