defmodule Events.Event do
  @derive [Poison.Encoder]
  defstruct source: "", source_id: "",  organization: nil, name: "",
    description: "", url: "", venue: "", address: "",
    start_time: DateTime.utc_now(), timestamp: 0, duration: 0,
    matched_keywords: [], is_series: false
end
