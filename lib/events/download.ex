require Logger


defmodule Events.Download do
  @hour 60 * 60

  def fetch_json(cache_name, url, params) do
    path = "cache/#{cache_name}.json"

    result = fetch(path, url, params)
    if result != nil do
      data = result |> Poison.decode!
      data |> Events.Util.to_json_file(path)
      data
    else
      nil
    end
  end

  def fetch(path, url, params) do
    if file_is_recent?(path) do
      Logger.info "Retrieving #{url} from cache"
      File.read!(path)
    else
      Logger.info "Downloading #{url} to #{path}"
      response = HTTPoison.get!(url, [], params: params)
      # Only return the data if response code was 200.
      if response.status_code == 200 do
        response.body
      else
        Logger.error "Got status code #{response.status_code} with response: #{response.body}"
        nil
      end
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
