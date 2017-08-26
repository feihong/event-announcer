defmodule Events.Event do
  @derive [Poison.Encoder]
  defstruct source: "", source_id: "",  name: "", description: "", url: "",
            venue: "", start_time: nil, timestamp: 0, matched_keywords: []
end
