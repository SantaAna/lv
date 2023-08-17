defmodule LvWeb.ConnectFour do
  use LvWeb, :live_view
  import LvWeb.ConnectFourComponents
  alias Lv.ConnectFour.Game
  alias Lv.GameServer
  alias Lv.LobbyServer
  alias Phoenix.PubSub

  @turn_time 60
  # TODO: refactor to use marker instead of color
  def mount(%{"lobby_id" => lobby_id, "state" => "joined"}, session, socket) do
    socket
    |> get_lobby_info(String.to_integer(lobby_id))
    |> exec_if_ok(
      &assign(&1, :user, Lv.Accounts.get_user_by_session_token(session["user_token"]))
    )
    |> exec_if_ok(fn socket ->
      if connected?(socket) do
        PubSub.broadcast(Lv.PubSub, "lobbies", {:delete, {:id, socket.assigns.lobby_id}})
        GameServer.player_join(socket.assigns.server, self(), socket.assigns.user)
        GameServer.start_game(socket.assigns.server)
      end

      socket
    end)
    |> exec_if_ok(
      &assign(&1, state: "started", multiplayer: true, turn_count: 0, turn_timer: @turn_time)
    )
    |> unwrap!()
    |> then(&{:ok, &1})
  end

  def mount(%{"lobby_id" => lobby_id, "state" => "waiting"}, session, socket) do
    socket
    |> get_lobby_info(String.to_integer(lobby_id))
    |> exec_if_ok(
      &assign(&1, :user, Lv.Accounts.get_user_by_session_token(session["user_token"]))
    )
    |> exec_if_ok(fn socket ->
      if connected?(socket),
        do: GameServer.player_join(socket.assigns.server, self(), socket.assigns.user)

      socket
    end)
    |> exec_if_ok(
      &assign(&1, state: "waiting", multiplayer: true, turn_count: 0, turn_timer: @turn_time)
    )
    |> unwrap!() 
    |> then(& {:ok, &1})
  end


  def mount(_params, _session, conn) do
    {:ok, server} = GameServer.start(module: Lv.ConnectFour.Game, module_arg: [])

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
    {:ok, server} = GameServer.start(module: Lv.ConnectFour.Game, module_arg: [])

    {:noreply,
     assign(conn,
       game: GameServer.get_game(server),
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

    {:noreply,
     assign(conn,
       state: "opponent-move",
       game: game,
       turn_timer: @turn_time,
       turn_count: conn.assigns.turn_count + 1
     )}
  end

  def handle_event("drop-piece", %{"col" => col}, conn) do
    play = String.to_integer(col)
    game = GameServer.player_move_single(conn.assigns.server, play)
    if game.winner || game.draw, do: GameServer.release(conn.assigns.server)
    {:noreply, assign(conn, game: game)}
  end

  def handle_event("kill-lobby", _params, socket) do
    PubSub.broadcast(Lv.PubSub, "lobbies", {:delete, {:id, socket.assigns.lobby_id}})
    {:noreply, push_navigate(socket, to: ~p"/")}
  end

  def handle_event("resign", _parmas, socket) do
    socket
    |> push_navigate(to: ~p"/")
    |> then(&{:noreply, &1})
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
    Process.send_after(self(), {:turn_tick, socket.assigns.turn_count}, 1000)
    {:noreply, assign(socket, game: game_state, state: "your-move")}
  end

  def handle_cast({:set_game, game}, socket) do
    {:noreply, assign(socket, game: game)}
  end

  def handle_call({:set_color, color}, _caller, socket) do
    {:reply, :ok, assign(socket, color: color)}
  end

  def handle_info({:turn_tick, _turn_count}, %{assigns: %{state: "opp-resigned"}} = socket),
    do: {:noreply, socket}

  def handle_info(
        {:turn_tick, turn_count},
        %{assigns: %{turn_count: turn_count, turn_timer: turn_timer}} = socket
      )
      when turn_timer > 0 do
    Process.send_after(self(), {:turn_tick, turn_count}, 1000)
    {:noreply, assign(socket, turn_timer: turn_timer - 1)}
  end

  def handle_info(
        {:turn_tick, turn_count},
        %{assigns: %{turn_count: turn_count, game: game, server: server, color: color}} = conn
      ) do
    play = Lv.Game.random_move(game)
    game = GameServer.player_move_multi(server, {play, color}, self())

    {:noreply,
     assign(conn,
       state: "opponent-move",
       game: game,
       turn_timer: @turn_time,
       turn_count: turn_count + 1
     )}
  end

  def handle_info({:turn_tick, _}, socket), do: {:noreply, socket}

  defp exec_if_ok({:ok, val}, fun), do: {:ok, fun.(val)}
  defp exec_if_ok({:error, val}, _fun), do: {:error, val}
  defp unwrap!({_, val}), do: val

  defp get_lobby_info(socket, lobby_id) do
    case LobbyServer.get_game(lobby_id) do
      {:ok, lobby_info} ->
        {:ok,
         assign(socket,
           server: lobby_info.game_server,
           game: GameServer.get_game(lobby_info.game_server),
           lobby_id: lobby_id
         )}

      {:error, _} ->
        {:error, push_navigate(socket, to: ~p"/")}
    end
  end
end
