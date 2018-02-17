require Logger


defmodule Events.Fetcher do
  use GenServer

  @minute 60 * 1000

  @doc """
  Fetch all events.
  """
  def fetch() do
    GenServer.call(__MODULE__, :fetch, @minute)
  end

  def start_link() do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def handle_call(:fetch, _from, state) do
    events =
      [Events.Facebook, Events.EventBrite, Events.Adhoc]
      |> Enum.map(fn mod -> apply(mod, :fetch_all, []) end)
      |> List.flatten
      |> Enum.filter(&in_near_future/1)
      |> Enum.filter(&not_read/1)
      |> Enum.sort_by(&sort_mapper/1)

    {:reply, events, state}
  end

  defp not_read(evt) do
    result = Events.ReadItem
      |> Events.Repo.get_by(source: evt.source, source_id: evt.source_id)
    result == nil
  end

  defp in_near_future(evt) do
    Timex.diff(evt.start_time, Timex.today(), :months) <= 4
  end

  defp sort_mapper(evt) do
    # Make sure that events that match keywords are always in front
    # regardless of start time.
    num = if length(evt.matched_keywords) > 0, do: 0, else: 1
    {num, evt.timestamp}
  end
end
