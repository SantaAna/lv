defmodule Lv.Matches do
  @moduledoc """
  The Matches context.
  """

  import Ecto.Query, warn: false
  alias Lv.Repo

  alias Lv.Matches.Match

  @doc """
  Returns the list of matches.

  ## Examples

      iex> list_matches()
      [%Match{}, ...]

  """
  def list_matches do
    Repo.all(Match)
  end

  @doc """
  Gets a single match.

  Raises `Ecto.NoResultsError` if the Match does not exist.

  ## Examples

      iex> get_match!(123)
      %Match{}

      iex> get_match!(456)
      ** (Ecto.NoResultsError)

  """
  def get_match!(id), do: Repo.get!(Match, id)

  @doc """
  Creates a match.

  ## Examples

      iex> create_match(%{field: value})
      {:ok, %Match{}}

      iex> create_match(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_match(attrs \\ %{}) do
    %Match{}
    |> Match.changeset(attrs)
    |> Repo.insert()
  end

  @spec record_match_result(integer, integer, String.t(), boolean) :: atom
  def record_match_result(winner_id, loser_id, game_name, draw?) do
    create_match(%{
      winner: winner_id,
      loser: loser_id,
      game: game_name,
      draw: draw?
    })
  end

  def matches_played_by_user(user_id) do
    q =
      from m in Match,
        join: w in "users",
        on: w.id == m.winner,
        join: l in "users",
        on: l.id == m.loser,
        where: m.winner == ^user_id or m.loser == ^user_id,
        order_by: [desc: m.inserted_at],
        select: %{
          winner_id: m.winner,
          winner_name: w.username,
          loser_id: m.loser,
          loser_name: l.username,
          game: m.game,
          draw: m.draw
        }

    Repo.all(q)
  end

  @doc """
  Updates a match.

  ## Examples

      iex> update_match(match, %{field: new_value})
      {:ok, %Match{}}

      iex> update_match(match, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_match(%Match{} = match, attrs) do
    match
    |> Match.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a match.

  ## Examples

      iex> delete_match(match)
      {:ok, %Match{}}

      iex> delete_match(match)
      {:error, %Ecto.Changeset{}}

  """
  def delete_match(%Match{} = match) do
    Repo.delete(match)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking match changes.

  ## Examples

      iex> change_match(match)
      %Ecto.Changeset{data: %Match{}}

  """
  def change_match(%Match{} = match, attrs \\ %{}) do
    Match.changeset(match, attrs)
  end
end
