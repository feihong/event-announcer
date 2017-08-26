defmodule Events.Util do
  def to_json_file(data, path) do
    data
      |> Poison.encode!(pretty: true)
      |> (fn text -> File.write(path, text) end).()
  end

  def from_json_file(path) do
    File.read!(path)
      |> Poison.decode!(as: [%Events.Event{}])
  end
end
