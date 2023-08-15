defmodule Lv.MatchCache do
  use GenServer
  alias Lv.Matches
  alias Phoenix.PubSub

  # client
  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def get_matches() do
    GenServer.call(__MODULE__, :get_matches)
  end

  def clear() do
    GenServer.call(__MODULE__, :clear)
  end

  # server 
  @impl true
  def init(_) do
    PubSub.subscribe(Lv.PubSub, "match_results")
    {:ok, Matches.recent_matches(10)}
  end

  @impl true
  def handle_call(:clear, _from, _state) do
    {:reply, :ok, []} 
  end

  @impl true
  def handle_call(:get_matches, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_info({:match_result, result}, state) do
    state =
      [result | state]
      |> Enum.take(10)

    {:noreply, state}
  end
end
