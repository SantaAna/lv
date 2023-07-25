defmodule Lv.TicTacToe.ComputerMoveServer do
  use GenServer
  alias Lv.TicTacToe.ComputerPlayer

  # public
  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def get_move(board) do
    GenServer.call(__MODULE__, {:move, board})
  end

  # private
  @impl true
  def init(_) do
    {:ok, %{}}
  end

  @impl true
  def handle_call({:move, board}, _from, cache) do
    if cache_result = Map.get(cache, board) do
      {:reply, cache_result, cache}
    else
      computer_move = ComputerPlayer.move(board, :perfect)
      {:reply, computer_move, Map.put(cache, board, computer_move)}
    end
  end
end
