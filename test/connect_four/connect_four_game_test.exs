defmodule ConnectFourGameTest do
  use ExUnit.Case 
  alias Lv.ConnectFour.Game, as: ConnectFour
  alias Lv.ConnectFour.Board
  
  defp alternator(:red_start) do
    Stream.cycle([:red, :black])
  end

  defp alternator(:black_start) do
    Stream.cycle([:black, :red])
  end

  describe "winner/1" do
    test "will return :no_winner for blank board" do
      b = Board.new() 
      assert :no_winner == ConnectFour.winner(%ConnectFour{board: b})
    end     

    test "will return {:winner, :red} for column winner" do

      b = Enum.reduce(1..4, Board.new(), fn _e, acc -> 
        {:ok, b} = Board.mark(acc, 0, :red)
        b
      end)

      assert ConnectFour.winner(%ConnectFour{board: b}) == {:winner, :red}
    end

    test "will return {:winner, :red} for row winner" do
      b = Enum.reduce(1..4, Board.new(), fn e, acc -> 
        {:ok, b} = Board.mark(acc, e, :red)
        b
      end)
      assert ConnectFour.winner(%ConnectFour{board: b}) == {:winner, :red}
    end

    test "will return {:winner, :black} for diag winner" do
       b = Enum.reduce(1..4, Board.new(), fn 
          e, acc when rem(e,2) == 0 -> 
          alternator(:red_start)
          |> Enum.take(6)
          |> Enum.reduce(acc, fn marker, board -> 
            {:ok, b} = Board.mark(board, e, marker)
            b
          end)
          e, acc -> 
          alternator(:black_start)
          |> Enum.take(6)
          |> Enum.reduce(acc, fn marker, board -> 
            {:ok, b} = Board.mark(board, e, marker)
            b
          end)
       end)
      assert ConnectFour.winner(%ConnectFour{board: b}) == {:winner, :black}
    end
  end  
end
