defmodule Events.Adhoc do
  @events_file "adhoc_events.json"

  @doc """
  Read adhoc events from a JSON file.
  """
  def fetch_all() do
    if File.exists?(@events_file) do
      Events.Util.from_json_file(@events_file)
    else
      []
    end
  end
end
