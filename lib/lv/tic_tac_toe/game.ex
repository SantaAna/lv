defmodule Lv.TicTacToe.Game do
  alias Lv.TicTacToe.Board
  alias Lv.TicTacToe.ComputerMoveServer
  defstruct [:board, :winner, :draw, winning_coords: []]

  @type t :: %__MODULE__{
          board: map,
          winner: nil | :player | :computer,
          draw: false | true
        }

  def new(_) do
    %__MODULE__{
      board: Board.new(),
      winner: nil,
      draw: false
    }
  end


  def mark(%__MODULE__{} = game, mark_spot, mark_symbol) do
    Map.update!(game, :board, fn board ->
      {:ok, new_board} = Board.mark(board, mark_spot, mark_symbol)
      new_board
    end)
  end

  def free_spaces(%__MODULE__{board: board}) do
    Board.free_spaces(board)
  end


  @spec winner(map) :: :no_winner | {true, atom}
  def winner(%__MODULE__{board: board} = game) do
    result =
      with :no_winner <- row_winner(board),
           :no_winner <- col_winner(board),
           :no_winner <- diag_winner(board) do
        :no_winner
      end

    case result do
      {true, :x, winning_coords} ->
        set_winner(game, :x, winning_coords)

      {true, :o, winning_coords} ->
        set_winner(game, :o, winning_coords)

      _ ->
        game
    end
  end

  def play_round(game, move) do
    game  
    |> mark(move, :x)
    |> winner()
    |> draw_check()
    |> computer_move()
    |> winner()
    |> draw_check()
  end

  def computer_move(%__MODULE__{winner: nil, draw: false} = game) do
    computer_move = Lv.ComputerMoveServer.get_move(game) 
    mark(game, computer_move, :o)
  end

  def computer_move(%__MODULE__{} = game), do: game
  

  def set_winner(%__MODULE__{winner: nil, draw: false} = game, winner, winning_coords) do
    Map.put(game, :winner, winner)
    |> Map.put(:winning_coords, winning_coords)
  end

  def set_winner(game, _, _) do
    game
  end

  def row_winner(board), do: all_same(Board.rows(board))
  def col_winner(board), do: all_same(Board.cols(board))
  def diag_winner(board), do: all_same(Board.diagonals(board))

  def all_same(groups) do
    for {_, group} <- groups, marker <- [:x, :o] do
      {Enum.all?(group, fn {_k, v} -> v == marker end), marker, Map.keys(group)}
    end
    |> Enum.find(:no_winner, fn {same, _marker, _coords} -> same end)
  end

  def draw_check(%__MODULE__{board: board, winner: nil, draw: false} = game) do
    if Board.fully_marked?(board) do
      Map.put(game, :draw, true)
    else
      game
    end
  end

  def draw_check(game), do: game
end
