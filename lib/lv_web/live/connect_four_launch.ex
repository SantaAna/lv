defmodule LvWeb.ConnectFourLaunch do
  use LvWeb, :live_view
  alias Phoenix.PubSub
  alias Lv.LobbyServer 

  @alias_to_game_module %{
    "connectfour" => [Lv.ConnectFour.Game, LvWeb.ConnectFour, "connectfour"],
    "tictactoe" => [Lv.TicTacToe.Game, LvWeb.TicTacToe, "ttt"]
  }

  def mount(_params, _session, socket) do
    PubSub.subscribe(Lv.PubSub, "lobbies")
    lobbies = LobbyServer.list_games() 
              |> Enum.filter(&(&1.status == :waiting_for_opponent))
              |> Enum.sort_by(& &1.id)
    {:ok, assign(socket, lobbies: lobbies)}
  end

  def render(assigns) do
    ~H"""
    <h1 class="text-4xl mb-3"> Start Playing </h1>
    <p> 
      You can join an existing lobby from the list below, play against the comptuer, or create your own lobby!
    </p>
    <div class="flex flex-col mt-3 mb-5">
      <h1 class="text-2xl mb-3 text-center"> Play Connect Four </h1>
      <div class="flex flex-row justify-evenly">
        <.link navigate={~p"/connectfour"}> 
        <.link_button>Play Connect Four Against Computer</.link_button>
        </.link>
        <.link_button phx-click="create-lobby" phx-value-game="connectfour">
          Create Connect Four Lobby
        </.link_button>
      </div>
      <h1 class="text-2xl mb-3 text-center mt-6"> Play TicTacToe </h1>
      <div class="flex flex-row justify-evenly">
        <.link navigate={~p"/ttt"}> 
        <.link_button>Play TicTacToe Against Computer</.link_button>
        </.link>
        <.link_button phx-click="create-lobby" phx-value-game="tictactoe">
          Create TicTacToe Lobby
        </.link_button>
      </div>
    </div>
    <h1 class="text-2xl mb-3 text-center mt-6"> Lobbies </h1>
    <div class="flex flex-col gap-5">
      <.lobby :for={lobby <- @lobbies} lobby={lobby} />
    </div>
    """
  end

  def lobby(assigns) do
    ~H"""
    <div class="flex flex-row gap-2 items-center">
      <div class="text-lg">
        <%= @lobby.game %>
      </div>
      <.link_button phx-click="join" phx-value-id={@lobby.id} phx-value-game={@lobby.game}>
      Join
      </.link_button>
    </div>
    """
  end

  def handle_info({:new, %{id: lobby_id}}, socket) do
    {:ok, lobby} = LobbyServer.get_game(lobby_id)
    lobbies = [lobby | socket.assigns.lobbies]
    {:noreply, assign(socket, lobbies: lobbies)} 
  end

  def handle_info({:delete, {:id, lobby_id}}, socket) do
    {:noreply, assign(socket, lobbies: Enum.reject(socket.assigns.lobbies, & &1.id == lobby_id))} 
  end

  def handle_event("join", %{"id" => id, "game" => game}, socket) do
    [_, _ , path] = @alias_to_game_module[game]
    {:noreply, push_navigate(socket, to: ~p"/#{path}?#{[lobby_id: id, state: "joined"]}")}
  end

  def handle_event("create-lobby", %{"game" => game_name}, socket) do
      [server_mod, player_mod, path] = @alias_to_game_module[game_name]
     id = LobbyServer.get_id()
     PubSub.broadcast(Lv.PubSub, "lobbies", {:new, %{id: id, mod: server_mod, player: player_mod}})

     {:noreply, push_navigate(socket, to: ~p"/#{path}?#{[lobby_id: id, state: "waiting"]}")}
  end

end
