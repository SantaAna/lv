defmodule Lv.Matches.Match do
  use Ecto.Schema
  import Ecto.Changeset

  schema "matches" do
    field :game, :string
    field :winner, :id
    field :loser, :id
    field :draw, :boolean

    timestamps()
  end

  @doc false
  def changeset(match, attrs) do
    match
    |> cast(attrs, [:game, :winner, :loser, :draw])
    |> validate_required([:game])
  end
end
