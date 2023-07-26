defmodule Lv.ConnectFour.ComputerPlayer do
  alias Lv.ConnectFour.Board
  alias Lv.ConnectFour.Game
  @spec move(map, :random | :perfect) :: integer
  def move(board, type \\ :random) do
    case type do
      :random -> random_move(board)
      :perfect -> perfect_move(board)
    end
  end

  @spec random_move(map) :: integer
  def random_move(board) do
    Board.open_cols(board)
    |> Enum.random()
  end

  @spec perfect_move(map) :: integer
  def perfect_move(board), do: minimax(board)

  @spec minimax(Board.t()) :: integer
  def minimax(board) do
    {:ok, cache_pid} = Agent.start_link(fn -> %{} end)
    {ret, _} = minimax(board, cache_pid, {5, 0})
    Agent.stop(cache_pid)
    ret
  end

  @spec minimax(Board.t(), pid, {integer, integer}, :red | :black) :: tuple
  def minimax(board, cache_pid, scry, turn \\ :black) do
    free_cols = Board.open_cols(board)

    case [free_cols, turn, Game.winner(%Game{board: board}), scry] do
      # these clauses return tuples so they are compatible with elem call.

      # if we've looked ahead the maximum number of turns, return draw
      [_, _, _, {s, s}] ->
        {nil, 0}

      [[], _, :no_winner, _] ->
        {nil, 0}

      [_, _, {:winner, :black}, _] ->
        {nil, 1}

      [_, _, {:winner, :red}, _] ->
        {nil, -1}

      # consider our moves
      [possible_moves, :black, _, {max, curr}] ->
        # create every possible board state.
        Enum.map(possible_moves, fn move ->
          {:ok, board} = Board.mark(board, move, :black)
          {move, board}
        end)
        # rate every board state according to its value recursively.
        |> Enum.map(fn {move, board} ->
          {
            move,
            # if the board state is already in the cache return it
            if cache = Agent.get(cache_pid, fn cache -> Map.get(cache, board, false) end) do
              cache
            else
              # get our val
              val = elem(minimax(board, cache_pid, {max, curr + 1}, :red), 1)
              # insert our val into our cache
              Agent.update(cache_pid, fn state ->
                Map.put(state, board, val)
              end)

              # pull value from cache, probably can replace with val
              Agent.get(cache_pid, fn state -> Map.get(state, board) end)
            end
          }
        end)
        # select the move with the maximum score
        |> Enum.max_by(fn {_move, score} -> score end)

      # opponent considers their moves
      [possible_moves, :red, _, {max, curr}] ->
        Enum.map(possible_moves, fn move ->
          {:ok, board} = Board.mark(board, move, :red)
          {move, board}
        end)
        |> Enum.map(fn {move, board} ->
          {move,
           if cache = Agent.get(cache_pid, fn cache -> Map.get(cache, board, false) end) do
             cache
           else
             val = elem(minimax(board, cache_pid, {max, curr + 1}, :black), 1)

             Agent.update(cache_pid, fn state ->
               Map.put(state, board, val)
             end)

             Agent.get(cache_pid, fn state -> Map.get(state, board) end)
           end}
        end)
        # here we take the minimum, since the opponent seeks to minimize our score.
        |> Enum.min_by(fn {_move, score} -> score end)
    end
  end
end
