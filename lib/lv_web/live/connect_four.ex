defmodule LvWeb.ConnectFour do
  use LvWeb, :live_view
  import LvWeb.ConnectFourComponents
  alias Lv.ConnectFour.Game
  alias Lv.GameServer
  alias Lv.LobbyServer
  alias Phoenix.PubSub

  def mount(%{"lobby_id" => lobby_id, "state" => "joined"}, _session, conn) do
    lobby_id = String.to_integer(lobby_id)
    {:ok, lobby_info} = LobbyServer.get_game(lobby_id)
    PubSub.broadcast(Lv.PubSub, "lobbies", {:delete, {:id, lobby_id}})
    GameServer.player_join(lobby_info.game_server, self())
    GameServer.start_game(lobby_info.game_server)

    {:ok,
     assign(conn,
       game: GameServer.get_game(lobby_info.game_server),
       server: lobby_info.game_server,
       state: "started",
       lobby_id: lobby_id,
       multiplayer: true
     )}
  end

  def mount(%{"lobby_id" => lobby_id, "state" => "waiting"}, _session, conn) do
    lobby_id = String.to_integer(lobby_id)
    {:ok, lobby_info} = LobbyServer.get_game(lobby_id)
    GameServer.player_join(lobby_info.game_server, self())

    {:ok,
     assign(conn,
       game: GameServer.get_game(lobby_info.game_server),
       server: lobby_info.game_server,
       state: "waiting",
       lobby_id: lobby_id,
       multiplayer: true
     )}
  end

  def mount(_params, _session, conn) do
    {:ok, server} = GameServer.start(module: Lv.ConnectFour.Game, module_args: [])

    {:ok,
     assign(conn,
       game: GameServer.get_game(server),
       server: server,
       state: "started",
       multiplayer: false,
       color: :red
     )}
  end

  def terminate(_reason, socket) do
    if socket.assigns.state in ["started", "opponent-move", "your-move"],
      do: GameServer.resign_game(socket.assigns.server, self())

    if socket.assigns.state == "waiting",
      do: PubSub.broadcast(Lv.PubSub, "lobbies", {:delete, {:id, socket.assigns.lobby_id}})
  end

  def handle_event("play-again", _params, conn) do
    {:ok, server} = GameServer.start()

    {:noreply,
     assign(conn,
       game: Game.new(computer_difficulty: :perfect),
       server: server
     )}
  end

  def handle_event(
        "drop-piece",
        %{"col" => col},
        %{assigns: %{multiplayer: true, color: color}} = conn
      ) do
    play = String.to_integer(col)
    game = GameServer.player_move_multi(conn.assigns.server, {play, color}, self())
    {:noreply, assign(conn, state: "opponent-move", game: game)}
  end

  def handle_event("drop-piece", %{"col" => col}, conn) do
    play = String.to_integer(col)
    game = GameServer.player_move_single(conn.assigns.server, play)
    if game.winner || game.draw, do: GameServer.release(conn.assigns.server)
    {:noreply, assign(conn, game: game)}
  end

  def handle_event("kill-lobby", _params, socket) do
    PubSub.broadcast(Lv.PubSub, "lobbies", {:delete, {:id, socket.assigns.lobby_id}})
    {:noreply, push_navigate(socket, to: ~p"/connectfour_launch")}
  end

  def handle_event("resign", _parmas, socket) do
    GameServer.resign_game(socket.assigns.server, self())
    {:noreply, push_navigate(socket, to: ~p"/connectfour_launch")}
  end

  # gen server functions

  # client
  def change_state(pid, state) do
    GenServer.cast(pid, {:change_state, state})
  end

  def take_turn(pid, game_state) do
    GenServer.cast(pid, {:take_turn, game_state})
  end

  def set_marker(pid, color) do
    GenServer.call(pid, {:set_color, color})
  end

  def set_game(pid, game) do
    GenServer.cast(pid, {:set_game, game})
  end

  # server
  def handle_cast({:change_state, state}, socket) do
    {:noreply, assign(socket, state: state)}
  end

  def handle_cast({:take_turn, game_state}, socket) do
    {:noreply, assign(socket, game: game_state, state: "your-move")}
  end

  def handle_cast({:set_game, game}, socket) do
    {:noreply, assign(socket, game: game)}
  end

  def handle_call({:set_color, color}, _caller, socket) do
    {:reply, :ok, assign(socket, color: color)}
  end
end
