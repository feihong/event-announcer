defmodule Events.ReadItem do
  use Ecto.Schema

  schema "read_items" do
    field :source, :string
    field :source_id, :string
    field :start_time, :utc_datetime
  end
end
