defmodule Events.ReadItem do
  use Ecto.Schema

  schema "read_items" do
    field :source, :string
    field :source_id, :string
    field :name, :string
    field :start_time, Timex.Ecto.DateTime
  end
end
