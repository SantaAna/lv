defmodule Lv.MatchesTest do
  use Lv.DataCase

  alias Lv.Matches

  describe "matches" do
    alias Lv.Matches.Match

    import Lv.MatchesFixtures
    import Lv.AccountsFixtures

    @invalid_attrs %{game: nil}

    test "record_match_result will record valid match" do
      winner = user_fixture() 
      loser = user_fixture() 
      {:ok, m} = Matches.record_match_result(winner.id, loser.id, "tictactoe", false)
      assert Matches.list_matches() == [m]
    end

    test "recent_matches will return correct results for sample smaller/larger/equal than table" do
      player1 = user_fixture()
      player2 = user_fixture()
      matches = for _x <- 1..3 do
        match_fixture(%{winner: player1.id, loser: player2.id})
      end

      assert length(Matches.recent_matches(2)) == 2
      assert length(Matches.recent_matches(10)) == 3
      assert length(Matches.recent_matches(3)) == 3
    end

    test "list_matches/0 returns all matches" do
      match = match_fixture()
      assert Matches.list_matches() == [match]
    end

    test "get_match!/1 returns the match with given id" do
      match = match_fixture()
      assert Matches.get_match!(match.id) == match
    end

    test "create_match/1 with valid data creates a match" do
      valid_attrs = %{game: "some game"}

      assert {:ok, %Match{} = match} = Matches.create_match(valid_attrs)
      assert match.game == "some game"
    end

    test "create_match/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Matches.create_match(@invalid_attrs)
    end

    test "update_match/2 with valid data updates the match" do
      match = match_fixture()
      update_attrs = %{game: "some updated game"}

      assert {:ok, %Match{} = match} = Matches.update_match(match, update_attrs)
      assert match.game == "some updated game"
    end

    test "update_match/2 with invalid data returns error changeset" do
      match = match_fixture()
      assert {:error, %Ecto.Changeset{}} = Matches.update_match(match, @invalid_attrs)
      assert match == Matches.get_match!(match.id)
    end

    test "delete_match/1 deletes the match" do
      match = match_fixture()
      assert {:ok, %Match{}} = Matches.delete_match(match)
      assert_raise Ecto.NoResultsError, fn -> Matches.get_match!(match.id) end
    end

    test "change_match/1 returns a match changeset" do
      match = match_fixture()
      assert %Ecto.Changeset{} = Matches.change_match(match)
    end
  end
end
