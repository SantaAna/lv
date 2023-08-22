defmodule Lv.Matches.Match do
  use Ecto.Schema
  import Ecto.Changeset

  schema "matches" do
    field :game, :string
    field :first_player, :id
    field :second_player, :id
    field :winner_id, :id

    timestamps()
  end

  @doc false
  def changeset(match, attrs) do
    match
    |> cast(attrs, [:game, :first_player, :second_player, :winner_id])
    |> validate_required([:game])
  end
end
