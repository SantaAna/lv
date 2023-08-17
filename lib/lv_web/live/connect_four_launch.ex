defmodule LvWeb.ConnectFourLaunch do
  use LvWeb, :live_view
  alias Phoenix.PubSub
  alias Lv.LobbyServer

  @alias_to_game_module %{
    "connectfour" => [Lv.ConnectFour.Game, LvWeb.ConnectFour, "connectfour"],
    "tictactoe" => [Lv.TicTacToe.Game, LvWeb.TicTacToe, "ttt"]
  }

  def mount(_params, session, socket) do
    PubSub.subscribe(Lv.PubSub, "lobbies")

    socket =
      socket
      |> assign_new(:current_user, fn ->
        if user_token = session["user_token"],
          do: Lv.Accounts.get_user_by_session_token(user_token)
      end)
      |> assign_new(:lobbies, fn ->
        LobbyServer.list_games()
        |> Enum.filter(&(&1.status == :waiting_for_opponent))
        |> Enum.sort_by(& &1.id)
      end)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <h1 class="text-4xl mb-3">Start Playing</h1>
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
    <div class="grid grid-cols-2 gap-4 mt-3">
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
    <h1 class="text-2xl mb-3 mt-6">Lobbies</h1>
    <div class="flex flex-col gap-5">
      <.lobby :for={lobby <- @lobbies} lobby={lobby} />
    </div>
    """
  end

  def lobby(assigns) do
    ~H"""
    <div class="flex flex-row gap-2 items-center shadow-lg p-4 rounded-md bg-slate-50 w-2/3 mx-auto">
      <.link_button phx-click="join" phx-value-id={@lobby.id} phx-value-game={@lobby.game}>
        Join
      </.link_button>
      <div class="flex flex-col text-lg w-36">
        <div class="flex flex-row justify-between">
          <p>
            Game:
          </p>
          <p>
            <%= @lobby.game %>
          </p>
        </div>
        <div class="flex flex-row justify-between">
          <p>
            Host:
          </p>
          <p>
            <%= @lobby.host %>
          </p>
        </div>
      </div>
    </div>
    """
  end

  def handle_info({:new, %{id: lobby_id, host: host}}, socket) do
    lobby_id
    |> LobbyServer.get_game()
    |> then(fn {:ok, lobby} -> Map.put(lobby, :host, host) end)
    |> then(&[&1 | socket.assigns.lobbies])
    |> then(&assign(socket, lobbies: &1))
    |> then(&{:noreply, &1})
  end

  def handle_info({:delete, {:id, lobby_id}}, socket) do
    {:noreply, assign(socket, lobbies: Enum.reject(socket.assigns.lobbies, &(&1.id == lobby_id)))}
  end

  def handle_event("join", _, %{assigns: %{current_user: nil}} = socket) do
    {:noreply, push_navigate(socket, to: ~p"/users/log_in")}
  end

  def handle_event("join", %{"id" => id, "game" => game}, socket) do
    [_, _, path] = @alias_to_game_module[game]
    {:noreply, push_navigate(socket, to: ~p"/#{path}?#{[lobby_id: id, state: "joined"]}")}
  end

  def handle_event("create-lobby", _, %{assigns: %{current_user: nil}} = socket) do
    {:noreply, push_navigate(socket, to: ~p"/users/log_in")}
  end

  def handle_event("create-lobby", %{"game" => game_name}, socket) do
    [server_mod, player_mod, path] = @alias_to_game_module[game_name]
    id = LobbyServer.get_id()

    PubSub.broadcast(
      Lv.PubSub,
      "lobbies",
      {:new,
       %{id: id, mod: server_mod, player: player_mod, host: socket.assigns.current_user.username}}
    )

    {:noreply, push_navigate(socket, to: ~p"/#{path}?#{[lobby_id: id, state: "waiting"]}")}
  end
end
