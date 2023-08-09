defmodule Lv.Repo.Migrations.CreateMatches do
  use Ecto.Migration

  def change do
    create table(:matches) do
      add :game, :string
      add :winner, references(:users, on_delete: :nothing)
      add :loser, references(:users, on_delete: :nothing)
      add :draw, :boolean

      timestamps()
    end

    create index(:matches, [:winner])
    create index(:matches, [:loser])
  end
end
