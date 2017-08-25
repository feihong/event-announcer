defmodule Events.Util do
  def to_json_file(data, path) do
    data
      |> Poison.encode!(pretty: true)
      |> (fn text -> File.write(path, text) end).()
  end
end
