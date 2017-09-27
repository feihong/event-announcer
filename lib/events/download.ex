require Logger


defmodule Events.Download do
  @day 24 * 60 * 60     # one day in seconds

  def fetch_json(cache_name, url, params) do
    path = "cache/#{cache_name}.json"

    # Don't write the downloaded content to file, it will be handled in this
    # function.
    {state, result} = fetch(path, url, params, false)
    data = result |> Poison.decode!
    if state == :fresh do
      data |> Events.Util.to_json_file(path)
    end
    data
  end

  def fetch_page(cache_name, url, params) do
    path = "cache/#{cache_name}.html"
    {_, html} = fetch(path, url, params)
    html
  end

  def fetch(path, url, params, writeFile \\ true) do
    if file_is_recent?(path) do
      Logger.info "Retrieving #{url} from cache"
      {:cache, File.read!(path)}
    else
      Logger.info "Downloading #{url} to #{path}"
      response = HTTPoison.get!(url, [], params: params)
      # Only return the data if response code was 200.
      if response.status_code == 200 do
        if writeFile do
          File.write(path, response.body)
        end
        {:fresh, response.body}
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
      DateTime.diff(DateTime.utc_now(), file_ctime_datetime(path)) < @day
  end

  # Get the ctime of the given file as a DateTime
  defp file_ctime_datetime(path) do
    File.stat!(path, time: :posix).ctime |> DateTime.from_unix!
  end
end
