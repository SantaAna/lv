defmodule Lv.ComputerPlayer do
  @default_scry 100

  @doc """
  Will return the computer move given a board.
  """

  def move(game, type \\ :random, opts \\ []) do
    case type do
      :random -> random_move(game)
      :perfect -> perfect_move(game, opts)
    end
  end

  @doc """
  Selects a random valid move. 
  """
  def random_move(game) do
    Lv.Game.possible_moves(game)
  end

  @doc """
  Will create the perfect computer move given the state of the board.
  Currently the only implemntation of perfect_move is the minimax function.
  """
  @spec perfect_move(map) :: list(integer)
  def perfect_move(game, opts \\ []) do
    [_human_marker, computer_marker] = Lv.Game.markers(game)

    opts =
      opts
      |> Keyword.put_new(:turn, computer_marker)
      |> Keyword.put_new(:look_ahead, @default_scry)

    elem(minimax(game, opts[:turn], {0, opts[:look_ahead]}), 0)
  end

  @doc """
  Implementation of the minimax function for tic-tac-toe with two symbols :x and :o. 
  The function assumes that the computer is playing with sybmol :o and the human is playing with symbol :x.
  """
  @spec minimax(map, :o | :x) :: {list(integer), integer}
  def minimax(game, turn \\ :o, scry \\ {0, @default_scry}) do
    possible_moves = Lv.Game.possible_moves(game)

    [human_marker, computer_marker] = Lv.Game.markers(game)

    game =
      game
      |> Lv.Game.win_check()
      |> Lv.Game.draw_check()

    case [turn, Lv.Game.draw?(game), Lv.Game.winner?(game), scry] do
      # these clauses return tuples so they are compatible with elem call.

      [_turn, true, _winner, _scry] ->
        {nil, 0}

      [^human_marker, _draw,  true,_scry] ->
        {nil, 1}

      [^computer_marker, _draw, true, _scry] ->
        {nil, -1}

      [_turn, _draw, _winner, {max, max}] ->
        {nil, 0}

      # consider our moves
      [^computer_marker, _draw, _winner, _scry] ->
        # create every possible board state.
        Enum.map(possible_moves, fn move ->
          game = Lv.Game.mark(game, move, computer_marker)
          {move, game}
        end)
        # rate every board state according to its value recursively.
        |> Enum.map(fn {move, game} ->
          {move, elem(minimax(game, human_marker, advance_scry(scry)), 1)}
        end)
        # select the move with the maximum score
        |> Enum.max_by(fn {_move, score} -> score end)

      # opponent considers their moves
      [^human_marker, _draw, _winner, _scry] ->
        Enum.map(possible_moves, fn move ->
          game = Lv.Game.mark(game, move, human_marker)
          {move, game}
        end)
        |> Enum.map(fn {move, game} ->
          {move, elem(minimax(game, computer_marker, advance_scry(scry)), 1)}
        end)
        # here we take the minimum, since the opponent seeks to minimize our score.
        |> Enum.min_by(fn {_move, score} -> score end)
    end
  end

  defp advance_scry({current, max}), do: {current + 1, max}
end
