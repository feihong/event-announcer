defmodule Events.Repo.Migrations.AddReadItems do
  use Ecto.Migration

  def change do
    create table(:read_items) do
      add :source, :string
      add :source_id, :string
      add :name, :string
      add :start_time, :utc_datetime
    end

    create index("read_items", [:source, :source_id], unique: true)
  end
end
