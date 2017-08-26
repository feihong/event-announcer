defmodule Events.Util do
  def to_json_file(data, path) do
    data
      |> Poison.encode!(pretty: true)
      |> (fn text -> File.write(path, text) end).()
  end

  def from_json_file(path) do
    File.read!(path)
      |> Poison.decode!(as: [%Events.Event{}])
      |> Enum.map(&convert_start_time/1)
  end

  defp convert_start_time(evt) do
    %{evt | start_time: Timex.parse!(evt.start_time, "{ISO:Extended}")}
  end
end
