defmodule Lv.MatchesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Lv.Matches` context.
  """

  @doc """
  Generate a match.
  """
  def match_fixture(attrs \\ %{}) do
    {:ok, match} =
      attrs
      |> Enum.into(%{
        game: "some game"
      })
      |> Lv.Matches.create_match()

    match
  end
end
