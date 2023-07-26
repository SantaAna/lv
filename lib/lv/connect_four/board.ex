defmodule Lv.ConnectFour.Board do
  @moduledoc """
  # Description
  Module for representing and manipulating a connect four board.
  """
  @type marker :: :red | :black | :blank
  @type t :: %{:size => integer, cols: list(list(marker))}

  @doc """
  Creates a new connect four board.
  """
  @spec new(integer) :: t
  def new(size \\ 6) do
    cols = Enum.map(1..size, fn _ -> List.duplicate(:blank, size) end)
    %{size: size, cols: cols}
  end

  @doc """
  Adds a marker to a row by dropping it down a column on the board.
  """
  @spec mark(t, integer, marker) :: {:ok, t} | {:error, String.t()}
  def mark(board, col_num, mark) do
    if col_full?(board, col_num) do
      {:error, "column is full"}
    else
      {:ok, trickle(board, col_num, mark)}
    end
  end

  @doc """
  Will return a list of all of the diagonals on the board.
  """
  @spec get_diagonals(t) :: list(list(marker))
  def get_diagonals(board) do
    for diagonal <- get_diagonal_coords(board), reduce: [] do
      acc ->
        [
          Enum.map(diagonal, &get_point(board, &1)),
          Enum.map(diagonal, &get_point(flip_board(board), &1))
          | acc
        ]
    end
  end
  
  @doc """
  Checks if a board is full by checking on all of the columns.
  """
  @spec full?(t) :: boolean
  def full?(board) do
    0..board.size-1
    |> Enum.map(&col_full?(board, &1))
    |> Enum.all?()
  end

  @spec open_cols(t) :: [integer]
  def open_cols(board) do
    0..board.size-1
    |> Enum.map(&[&1, col_full?(board, &1)])
    |> Enum.filter(& not List.last(&1))
    |> Enum.map(& List.first(&1))
  end

  @doc """
  Will return a list of all columns on the board
  """
  @spec get_cols(t) :: list(list(marker))
  def get_cols(board) do
    for col <- 0..(board.size - 1), do: get_col(board, col)
  end

  @doc """
  Will return a list of all rows on the board.
  """
  @spec get_rows(t) :: list(list(marker))
  def get_rows(board) do
    for row <- 0..(board.size - 1), do: get_row(board, row)
  end
  
  #gets a particular column
  @spec get_col(t, integer) :: list(marker)
  defp get_col(board, col_num) do
    board
    |> Map.get(:cols)
    |> Enum.at(col_num)
  end
  
  #gets a particular row
  @spec get_row(t, integer) :: list(marker)
  defp get_row(board, row_num) do
    board.cols
    |> Enum.map(&Enum.at(&1, row_num))
  end

  # flips the board such that we can examine negative and positive diagonals 
  # using the same set of co-ordinates
  #     
  #      ^                      \
  #     /   - reverse cols   ->  \
  #    /                          v
  #      
  @spec flip_board(t) :: t
  defp flip_board(board) do
    Map.update!(board, :cols, &Enum.map(&1, fn col -> Enum.reverse(col) end))
  end

  # gets all diagonals co-ordinates on a board by taking 
  # a number of elements equal to board size from a line and then rejecting
  # any co-ordinates outside of the board
  @spec get_diagonal_coords(t) :: list(list({integer, integer}))
  defp get_diagonal_coords(board) do
    for x <- 0..(board.size - 1), y <- 0..(board.size - 1), x == 0 or y == 0 do
      generate_line({x, y}, 1)
      |> Enum.take(board.size)
      |> Enum.reject(fn {x, y} -> x >= board.size or y >= board.size end)
    end
  end

  # returns a stream that will generate points along a line with the given slope.
  @spec generate_line({integer, integer}, integer) :: Stream.t()
  defp generate_line(start, slope) do
    Stream.iterate(start, fn {x, y} -> {x + 1, y + slope} end)
  end

  # checks if a col is full reducing all col values into
  # a bool that starts true and is flipped if a blank spot is
  # encountered
  @spec col_full?(t, integer) :: boolean
  def col_full?(board, col_num) do
    get_col(board, col_num)
    |> Enum.reduce(true, fn
      :blank, _ -> false
      _, acc -> acc
    end)
  end

  # Simulates a marker falling down a column.
  @spec trickle(t, integer, marker) :: t
  defp trickle(board, col_num, mark) do
    Map.update!(board, :cols, fn cols ->
      List.update_at(cols, col_num, &trickle_col(&1, mark))
    end)
  end

  # use chunk to peak ahead for each move down, if the
  # current element is blank and the next is non-blank
  # the marker is stopped.
  @spec trickle_col(list(marker), marker) :: list(marker)
  defp trickle_col(col, mark) do
    col
    |> Enum.chunk_every(2, 1)
    |> Enum.map(fn
      [:blank, ele] when ele != :blank -> mark
      [ele, _] -> ele
      [:blank] -> mark
      [ele] -> ele
    end)
  end

  # gets a point on the board.  These
  # co-ordinates may not correspond to 
  # what is displayed by the user and 
  # this function should not be used for display
  @spec get_point(t, {integer, integer}) :: marker
  defp get_point(board, {x, y}) do
    board.cols
    |> Enum.at(x)
    |> Enum.at(board.size - y - 1)
  end
end
