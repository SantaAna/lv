defmodule LvWeb.ConnectFourLaunch do
  use LvWeb, :live_view
  alias Phoenix.PubSub
  alias Lv.ConnectFour.GameTrackerServer, as: TrackerServer

  def mount(_params, _session, socket) do
    PubSub.subscribe(Lv.PubSub, "lobbies")
    lobbies = TrackerServer.list_games() 
              |> Enum.filter(&(&1.status == :waiting_for_opponent))
              |> Enum.sort_by(& &1.id)
    {:ok, assign(socket, lobbies: lobbies)}
  end

  def render(assigns) do
    ~H"""
    <div class="flex flex-row justify-evenly">
      <.link navigate={~p"/connectfour"}> 
      <button>Play Against Computer</button>
      </.link>
      <button phx-click="create-lobby">
        Create Lobby
      </button>
    </div>
    <div class="flex flex-col gap-5">
      <.lobby :for={lobby <- @lobbies} lobby={lobby} />
    </div>
    """
  end

  def lobby(assigns) do
    ~H"""
    <div class="flex flex-row gap-2">
      <div>
        <%= @lobby.id %>
      </div>
      <button phx-click="join" phx-value-id={@lobby.id}>
      Join
      </button>
    </div>
    """
  end

  def handle_info({:new, {:id, lobby_id}}, socket) do
    {:ok, lobby} = TrackerServer.get_game(lobby_id)
    lobbies = [lobby | socket.assigns.lobbies]
    {:noreply, assign(socket, lobbies: lobbies)} 
  end

  def handle_info({:delete, {:id, lobby_id}}, socket) do
    {:noreply, assign(socket, lobbies: Enum.reject(socket.assigns.lobbies, & &1 == lobby_id))} 
  end

  def handle_event("join", %{"id" => id}, socket) do
    {:noreply, push_navigate(socket, to: ~p"/connectfour?#{[lobby_id: id, state: "joined"]}")}
  end

  def handle_event("create-lobby", _params, socket) do
     id = TrackerServer.get_id()
     PubSub.broadcast(Lv.PubSub, "lobbies", {:new, {:id, id}})

     {:noreply, push_navigate(socket, to: ~p"/connectfour?#{[lobby_id: id, state: "waiting"]}")}
  end

end
