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

  @spec record_match_result(integer, integer, String.t(), boolean) :: {:ok, Ecto.Schema.t} | {:error, Ecto.Changeset.t}
  def record_match_result(player1, player2, game_name, winner) do
    create_match(%{
      first_player: player1,
      second_player: player2,
      game: game_name,
      winner_id: winner
    })
  end

  def recent_matches(match_count) do
    q =
      from m in Match,
        join: p1 in "users",
        on: p1.id == m.first_player,
        join: p2 in "users",
        on: p2.id == m.second_player,
        order_by: [desc: m.inserted_at],
        limit: ^match_count,
        select: %{
          id: m.id,
          first_player_id: p1.id,
          first_player_name: p1.username,
          second_player_id: p2.id,
          second_player_name: p2.username,
          game: m.game,
          winner_id: m.winner_id
        }

    Repo.all(q)
  end

  def matches_played_by_user(user_id) do
    q =
      from m in Match,
        join: p1 in "users",
        on: p1.id == m.first_player,
        join: p2 in "users",
        on: p2.id == m.second_player,
        where: m.first_player == ^user_id or m.second_player == ^user_id,
        order_by: [desc: m.inserted_at],
        select: %{
          first_player_id: p1.id,
          first_player_name: p1.username,
          second_player_id: p2.id,
          second_player_name: p2.username,
          game: m.game,
          winner_id: m.winner_id
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
