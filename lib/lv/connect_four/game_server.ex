defmodule Lv.ConnectFour.GameServer do
  use GenServer 
  alias Lv.ConnectFour.Game
  #client side
  def start(opts \\ []) do
    opts = Keyword.put_new(opts, :computer_difficulty, :perfect)
    GenServer.start(__MODULE__,opts) 
  end



  def player_move_single(pid, column) do
    GenServer.call(pid, {:player_move, column})
  end

  def release(pid) do
    GenServer.stop(pid, :shutdown)
  end
  
  #server side
  def init(opts) do
    {:ok, Game.new(opts)} 
  end

  def handle_call({:player_move, column}, _from, state) do
    updated_game = Game.play_round(state, column) 
    {:reply, updated_game, updated_game} 
  end

end
