defmodule Events.Adhoc do
  @events_file "adhoc_events.json"
  @keywords Application.fetch_env!(:events, :keywords)

  @doc """
  Read adhoc events from a JSON file.
  """
  def fetch_all() do
    if File.exists?(@events_file) do
      @events_file
      |> Events.Util.from_json_file()
      |> Enum.map(fn evt -> Events.Util.match_keywords(evt, @keywords) end)
    else
      []
    end
  end
end
