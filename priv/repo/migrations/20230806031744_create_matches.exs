defmodule Lv.Repo.Migrations.CreateMatches do
  use Ecto.Migration

  def change do
    create table(:matches) do
      add :game, :string
      add :first_player, references(:users, on_delete: :nothing)
      add :second_player, references(:users, on_delete: :nothing)
      add :winner_id, references(:users, on_delete: :nothing)

      timestamps()
    end

    create index(:matches, [:first_player])
    create index(:matches, [:second_player])
  end
end
