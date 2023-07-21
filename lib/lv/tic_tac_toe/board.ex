defmodule Lv.TicTacToe.Board do
  def new(size \\ 3) do
    for row <- 1..size, col <- 1..size, into: %{size: size} do
      {[row, col], :blank}
    end
  end

  @spec mark(map, list, String.t() | atom) :: {:ok, map} | {:error, String.t()}
  def mark(board, [_row, _col] = mark_spot, mark_symbol) do
    if is_blank?(board, mark_spot) do
      board = Map.put(board, mark_spot, mark_symbol)
      {:ok, board}
    else
      {:error, "cannot mark over existing non-blank symbol."}
    end
  end

  def fully_marked?(board) do
    for x <- 1..board.size, y <- 1..board.size, reduce: true do
      false -> false
      true -> not is_blank?(board, [x, y])
    end
  end

  def free_spaces(board) do
    Enum.filter(board, fn {_k, v} -> v == :blank end)
  end

  @spec is_blank?(map, list) :: boolean
  def is_blank?(board, [_row, _col] = mark_spot) do
    board[mark_spot] == :blank
  end

  def rows(%{size: size} = board) do
    for row <- 1..size, into: %{}, do: {row, row(board, row)}
  end

  def cols(%{size: size} = board) do
    for col <- 1..size, into: %{}, do: {col, col(board, col)}
  end

  def row(board, row_number) do
    for {[row, _col] = position, mark} <- board,
        row == row_number,
        into: %{},
        do: {position, mark}
  end

  def col(board, col_number) do
    for {[_row, col] = position, mark} <- board,
        col == col_number,
        into: %{},
        do: {position, mark}
  end

  def diagonals(board) do
    %{
      left_right_diagonal: left_right_diagonal(board),
      right_left_diagonal: right_left_diagonal(board)
    }
  end

  def left_right_diagonal(board) do
    for {[row, col] = position, mark} <- board, row == col, into: %{}, do: {position, mark}
  end

  def right_left_diagonal(%{size: size} = board) do
    for {[row, col] = position, mark} <- board,
        col == size - row + 1,
        into: %{},
        do: {position, mark}
  end
end
