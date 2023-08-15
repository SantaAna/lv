defmodule Lv.MatchCacheTest do
  use ExUnit.Case
  alias Phoenix.PubSub
  alias Lv.MatchCache

  @game_names ["tictactoe", "connectfour"]

  test "receives updates from pubsub" do
    MatchCache.clear()
    match_result = %{
      id: Enum.random(1..100),
      draw: Enum.random([true, false]),
      game: Enum.random(@game_names),
      winner_id: Enum.random(1..100),
      loser_id: Enum.random(1..100),
      winner_name: Faker.Person.first_name(),
      loser_name: Faker.Person.last_name()
    }
    PubSub.broadcast(Lv.PubSub, "match_results", {:match_result, match_result})
    assert MatchCache.get_matches() == [match_result]
  end

  test "preserves order from pubsub" do
    MatchCache.clear()
    matches = for _x <- 1..10 do
      match_result = %{
        id: Enum.random(1..100),
        draw: Enum.random([true, false]),
        game: Enum.random(@game_names),
        winner_id: Enum.random(1..100),
        loser_id: Enum.random(1..100),
        winner_name: Faker.Person.first_name(),
        loser_name: Faker.Person.last_name()
      }
    end

    Enum.each(matches, & PubSub.broadcast(Lv.PubSub, "match_results", {:match_result, &1}))

    assert MatchCache.get_matches() == Enum.reverse(matches)
  end

  test "will only store ten most recent matches" do
    MatchCache.clear()
    matches = for _x <- 1..20 do
      match_result = %{
        id: Enum.random(1..100),
        draw: Enum.random([true, false]),
        game: Enum.random(@game_names),
        winner_id: Enum.random(1..100),
        loser_id: Enum.random(1..100),
        winner_name: Faker.Person.first_name(),
        loser_name: Faker.Person.last_name()
      }
    end
    Enum.each(matches, & PubSub.broadcast(Lv.PubSub, "match_results", {:match_result, &1}))
    assert MatchCache.get_matches() == matches |> Enum.reverse() |> Enum.take(10)
  end
end
