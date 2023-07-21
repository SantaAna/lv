defmodule Lv.TicTacToe.ComputerPlayer do
  alias Lv.TicTacToe.{Board, Game}


  @doc """
  Will return the computer move given a board.
  """
  @spec move(map, :random | :perfect) :: list(integer)
  def move(board, type \\ :random) do
    case type do
      :random -> random_move(board)
      :perfect -> perfect_move(board)
    end
  end

  @doc """
  Selects a random valid move. 
  """
  @spec random_move(map) :: list(integer)
  def random_move(board) do
    Board.free_spaces(board)
    |> Enum.random()
    |> elem(0)
  end

  @doc """
  Will create the perfect computer move given the state of the board.
  Currently the only implemntation of perfect_move is the minimax function.
  """
  @spec perfect_move(map) :: list(integer)
  def perfect_move(board), do: elem(minimax(board), 0)

  @doc """
  Implementation of the minimax function for tic-tac-toe with two symbols :x and :o. 
  The function assumes that the computer is playing with sybmol :o and the human is playing with symbol :x.
  """
  @spec minimax(map, :o | :x) :: {list(integer), integer}
  def minimax(board, turn \\ :o) do
    free_spaces = Board.free_spaces(board) |> Enum.unzip() |> elem(0)

    case [free_spaces, turn, Game.winner(board)] do
      #these clauses return tuples so they are compatible with elem call.
      [[], _, :no_winner] ->
        {nil, 0}

      [_, _, {true, :o}] ->
        {nil, 1}

      [_, _, {true, :x}] ->
        {nil, -1}

      #consider our moves
      [possible_moves, :o, _] ->
        #create every possible board state.
        Enum.map(possible_moves, fn move ->
          {:ok, board} = Board.mark(board, move, :o)
          {move, board}
        end)
        #rate every board state according to its value recursively.
        |> Enum.map(fn {move, board} -> {move, elem(minimax(board, :x), 1)} end)
        #select the move with the maximum score
        |> Enum.max_by(fn {_move, score} -> score end)
      
      #opponent considers their moves
      [possible_moves, :x, _] ->
        Enum.map(possible_moves, fn move ->
          {:ok, board} = Board.mark(board, move, :x)
          {move, board}
        end)
        |> Enum.map(fn {move, board} -> {move, elem(minimax(board, :o), 1)} end)
        #here we take the minimum, since the opponent seeks to minimize our score.
        |> Enum.min_by(fn {_move, score} -> score end)
    end
  end
end
