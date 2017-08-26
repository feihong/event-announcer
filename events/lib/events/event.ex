defmodule Events.Event do
  @derive [Poison.Encoder]
  defstruct source: "", source_id: "",  name: "", description: "", url: "",
            venue: "", start_time: DateTime.utc_now(), timestamp: 0,
            duration: 0, matched_keywords: []
end
