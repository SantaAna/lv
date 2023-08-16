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
    <div class="flex flex-col gap-4">
      <p> 
      Join an existing lobby from the list below to play against a human opponenent.
      If you don't see a game you are interested in create your own lobby and wait for an opponent.
      </p>
      <p> 
      If your looking for a challenge start a game against a computer opponent.
      The computer will always be planning a few moves ahead so make sure to think twice before you move.
      </p>
    </div>
    <.link navigate={~p"/match-activity"}>
    <.link_button> Check the Match Feed </.link_button>
    </.link>
    <div class="grid grid-cols-2 gap-4">
        <.link navigate={~p"/connectfour"}> 
        <.link_button>Play Connect Four Against Computer</.link_button>
        </.link>
        <.link_button phx-click="create-lobby" phx-value-game="connectfour">
          Create Connect Four Lobby
        </.link_button>
        <.link navigate={~p"/ttt"}> 
        <.link_button>Play TicTacToe Against Computer</.link_button>
        </.link>
        <.link_button phx-click="create-lobby" phx-value-game="tictactoe">
          Create TicTacToe Lobby
        </.link_button>
    </div>
    <h1 class="text-2xl mb-3 mt-6"> Lobbies </h1>
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
