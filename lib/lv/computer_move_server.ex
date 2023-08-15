defmodule Lv.ComputerMoveServer do
  use GenServer

  # public
  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def get_move(game, opts \\ []) do
    GenServer.call(__MODULE__, {:move, game, opts})
  end

  # private
  @impl true
  def init(_) do
    {:ok, %{}}
  end

  @impl true
  def handle_call({:move, game, opts}, _from, cache) do
    if cache_result = Map.get(cache , {game, opts}) do
      {:reply, cache_result, cache}
    else
      computer_move = Lv.ComputerPlayer.move(game, :perfect, opts)
      {:reply, computer_move, Map.put(cache, {game, opts}, computer_move)}
    end
  end
end
