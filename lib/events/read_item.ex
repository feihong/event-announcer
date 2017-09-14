defmodule Events.ReadItem do
  use Ecto.Schema

  @allowed [:source, :source_id, :name, :start_time]

  schema "read_items" do
    field :source, :string
    field :source_id, :string
    field :name, :string
    field :start_time, :utc_datetime
  end

  def changeset(model, params) do
    model
    |> Ecto.Changeset.cast(params, @allowed)
  end

  def changeset(%{}=params) do
    changeset(%__MODULE__{}, params)
  end
end
