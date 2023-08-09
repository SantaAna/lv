defmodule Lv.MatchCache do
  use GenServer
  alias Lv.Matches
  alias Lv.Accounts
  alias Phoenix.PubSub
  
  #client
  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end 

  def get_matches() do
    GenServer.call(__MODULE__, :get_matches)
  end

  #server 
  @impl true
  def init(_) do
    PubSub.subscribe(Lv.PubSub,"match_results") 
    {:ok, Matches.recent_matches(10)}
  end

  @impl true
  def handle_call(:get_matches, _from, state) do
    {:reply, state, state} 
  end

  @impl true
  def handle_info({:match_result, result}, state) do
    result = result
            |> Map.put(:winner_name, Accounts.get_user!(result.winner_id).username)
            |> Map.put(:loser_name, Accounts.get_user!(result.loser_id).username)

    state = [result | state]
    |> Enum.take(10)
    {:noreply, state}
  end 
end
