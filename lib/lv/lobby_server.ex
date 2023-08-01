defmodule Lv.LobbyServer do
  use GenServer
  alias Phoenix.PubSub
  alias Lv.Lobby

  # client side
  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def add_game(game_info) do
    GenServer.call(__MODULE__, {:add_game, game_info})
  end

  def get_game(id) when is_integer(id) do
    GenServer.call(__MODULE__, {:get_game, id}) 
  end

  def get_id() do
    GenServer.call(__MODULE__, :get_id)
  end

  def remove_game(id) do
    GenServer.call(__MODULE__, {:remove_game, id})
  end

  def update_game(id, new_game) do
    GenServer.call(__MODULE__, {:update_game, id, new_game})
  end

  def list_games do
    GenServer.call(__MODULE__, :list_games)
  end

  # server side
  @impl true
  def init(_) do
    PubSub.subscribe(Lv.PubSub, "lobbies") 
    {:ok, {[], 1}}
  end
  
  @impl true
  def handle_info({:new, %{id: id, mod: module}}, {games, current_id}) do
    tracker = Lobby.new(id, module) 
    {:noreply, {[tracker | games], current_id}}
  end

  @impl true
  def handle_info({:delete, {:id, id}}, {games, current_id}) do
    games = Enum.reject(games, & &1.id == id) 
    {:noreply, {games, current_id}}
  end

  @impl true
  def handle_call({:get_game, id}, _caller, {games, _} = state) do
    if game = Enum.find(games, & &1.id == id) do
      {:reply, {:ok, game}, state}
    else
      {:reply, {:error, "game not in list"}, state}
    end
  end

  @impl true
  def handle_call(:get_id, _caller, {games, current_id}) do
    {:reply, current_id, {games, current_id + 1}}
  end

  @impl true
  def handle_call({:update_game, id, new_game}, _caller, {games, current_id} = state) do
    if id in (Enum.map(games, & &1.id)) do
      updated = [new_game | Enum.reject(games, &(&1.id == id))]
      {:reply, updated, {updated, current_id}}
    else
      {:reply, {:error, "game not in list"}, state}
    end
  end

  @impl true
  def handle_call({:remove_game, id}, _caller, {games, current_id}) do
    updated = Enum.reject(games, &(&1.id == id))
    {:reply, updated, {updated, current_id}}
  end

  @impl true
  def handle_call({:add_game, game_info}, _caller, {games, current_id}) do
    games = [Map.put(game_info, :id, current_id) | games]
    {:reply, games, {games, current_id + 1}}
  end

  @impl true
  def handle_call(:list_games, _caller, {games, _} = state), do: {:reply, games, state}
end
