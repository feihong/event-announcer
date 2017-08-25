require Logger


defmodule Events.Download do
  @hour 60 * 60

  def fetch(cache_name, url, params) do
    path = "cache_pages/#{cache_name}.json"

    if file_is_recent?(path) do
      Logger.info "Retrieving #{cache_name} from cache"
      File.read!(path)
      |> Poison.decode!
    else
      Logger.info "Downloading #{cache_name} from #{url}"
      data = HTTPoison.get!(url, [], params: params)
        |> (fn response -> response.body end).()
        |> Poison.decode!

      data |> Events.Util.to_json_file(path)
      data
    end
  end

  # Returns true if the file at the given path exists and was created less than
  # 24 hours ago; false otherwise.
  defp file_is_recent?(path) do
    File.exists?(path) and
      DateTime.diff(DateTime.utc_now(), file_ctime_datetime(path)) < (24 * @hour)
  end

  # Get the ctime of the given file as a DateTime
  defp file_ctime_datetime(path) do
    File.stat!(path, time: :posix).ctime |> DateTime.from_unix!
  end
end
