defmodule Lv.TicTacToe.Game do
  alias Lv.TicTacToe.Board

  @spec winner(map) :: :no_winner | {true, atom}
  def winner(board) do
    with :no_winner <- row_winner(board),
         :no_winner <- col_winner(board),
         :no_winner <- diag_winner(board) do
      :no_winner
    end
  end

  def row_winner(board), do: all_same(Board.rows(board))
  def col_winner(board), do: all_same(Board.cols(board))
  def diag_winner(board), do: all_same(Board.diagonals(board))

  def all_same(groups) do
    for {_, group} <- groups, marker <- [:x, :o] do
      {Enum.all?(group, fn {_k, v} -> v == marker end), marker}
    end
    |> Enum.find(:no_winner, fn {same, _marker} -> same end)
  end

  def draw_check(board) do
    case [winner(board), Board.fully_marked?(board)] do
      [{true, _}, _] -> false
      [_, true] -> true
      _ -> false
    end
  end
end
