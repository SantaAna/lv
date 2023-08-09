defmodule LvWeb.TicTacToe do
  use LvWeb, :live_view
  alias Phoenix.PubSub
  alias Lv.LobbyServer
  alias Lv.GameServer
  import LvWeb.ConnectFourComponents

  @turn_time 10

  def mount(%{"lobby_id" => lobby_id, "state" => "joined"}, session, socket) do
    user = Lv.Accounts.get_user_by_session_token(session["user_token"])
    lobby_id = String.to_integer(lobby_id)
    {:ok, lobby_info} = LobbyServer.get_game(lobby_id)
    PubSub.broadcast(Lv.PubSub, "lobbies", {:delete, {:id, lobby_id}})
    GameServer.player_join(lobby_info.game_server, self())
    GameServer.start_game(lobby_info.game_server)

    {:ok,
     assign(socket,
       game: GameServer.get_game(lobby_info.game_server),
       server: lobby_info.game_server,
       state: "started",
       lobby_id: lobby_id,
       multiplayer: true,
       turn_count: 0,
       turn_timer: @turn_time
     )}
  end

  def mount(%{"lobby_id" => lobby_id, "state" => "waiting"}, _session, socket) do
    lobby_id = String.to_integer(lobby_id)
    {:ok, lobby_info} = LobbyServer.get_game(lobby_id)
    GameServer.player_join(lobby_info.game_server, self())

    {:ok,
     assign(socket,
       game: GameServer.get_game(lobby_info.game_server),
       server: lobby_info.game_server,
       state: "waiting",
       lobby_id: lobby_id,
       multiplayer: true,
       turn_count: 0,
       turn_timer: @turn_time
     )}
  end

  def mount(_params, _session, socket) do
    {:ok, server} = Lv.GameServer.start(module: Lv.TicTacToe.Game, module_arg: [])

    {:ok,
     assign(socket,
       server: server,
       state: "play",
       multiplayer: false,
       marker: :x,
       game: Lv.GameServer.get_game(server)
     )}
  end

  def render(assigns) do
    ~H"""
    <div class="flex justify-center">
      <div>
        <h1 class="text-center text-2xl mb-5">Tic-Tac-Toe</h1>
        <%= case [@state, @multiplayer] do %>
          <% ["waiting", true] -> %>
            <h2>Waiting for an opponenet to Join</h2>
            <.negative_button phx-click="kill-lobby">Leave Lobby</.negative_button>
          <% ["started", true] -> %>
            <h2>Game is Starting</h2>
            <.board game={@game} interact={false} />
          <% ["opponent-move", true] -> %>
            <h2>Waiting for opponent to move</h2>
            <.board game={@game} interact={false} />
            <.negative_button phx-click="resign">Resign</.negative_button>
          <% ["your-move", true] -> %>
            <div class="flex flex-col mx-auto justify-evenly attentionGreen rounded-md">
              <h2>Your Move!</h2>
              <h2> Seconds left: <%= @turn_timer %> </h2> 
            </div>
            <.board game={@game} interact={true} />
            <.negative_button phx-click="resign">Resign</.negative_button>
          <% ["opp-resigned", true] -> %>
            <h2 class="text-green-500 text-2xl text-center mb-2">
              You Win!
            </h2>
            <h3>Your Opponent Resigned</h3>
            <.board game={@game} interact={false} />
            <.link navigate={~p"/"}>
              <.link_button>
                Return to Lobby
              </.link_button>
            </.link>
          <% ["game-over", true] -> %>
            <%= cond do %>
              <% @game.draw -> %>
                <h2 class="text-yellow-500 text-2xl text-center mb-2">Cat's Game!</h2>
              <% @game.winner == @marker  -> %>
                <h2 class="text-green-500 text-2xl text-center mb-2">
                  You Win!
                </h2>
              <% true -> %>
                <h2 class="text-red-500 text-2xl text-center mb-2">
                  You Lose!
                </h2>
            <% end %>
            <.board game={@game} interact={false} />
            <.link navigate={~p"/"}>
              <.link_button>
                Return to Lobby
              </.link_button>
            </.link>
          <% [_, false] -> %>
            <h2 :if={@game.draw} class="text-yellow-500 text-2xl text-center mb-2">
              Cat's Game!
            </h2>
            <h2 :if={@game.winner == :x} class="text-green-500 text-2xl text-center mb-2">
              You Win!
            </h2>
                <h2 :if={@game.winner == :o} class="text-red-500 text-2xl text-center mb-2">
                  You Lose!
                </h2>
            <.board game={@game} interact={!@game.winner && !@game.draw} />
            <div class="flex justify-center">
              <button
                :if={@game.draw || @game.winner}
                class="bg-black text-zinc-50 p-4 mt-5 hover:bg-gray-700"
                phx-click="play-again"
              >
                Play Again
              </button>
            </div>
        <% end %>
      </div>
    </div>
    """
  end

  def board(assigns) do
    ~H"""
    <div class="grid grid-cols-3 h-52 w-52">
      <%= for x <- 1..3, y <- 1..3 do %>
        <.board_square coord={[x, y]} game={@game} interact={@interact} />
      <% end %>
    </div>
    """
  end

  def board_square(assigns) do
    ~H"""
    <%= case [@game.board[@coord], @coord in @game.winning_coords] do %>
      <% [:blank, _] -> %>
        <%= if !@interact do %>
          <div class="p-5 text-xl border-black border-2 text-center h-full w-full text-transparent hover:bg-red-100">
            B
          </div>
        <% else %>
          <div
            class="p-5 text-xl border-black border-2 text-center h-full w-full text-transparent hover:bg-green-100"
            phx-click="mark"
            phx-value-row={Enum.at(@coord, 0)}
            phx-value-col={Enum.at(@coord, 1)}
          >
            B
          </div>
        <% end %>
      <% [:x, false] -> %>
        <div class="p-5 text-xl border-black border-2 text-center h-full w-full hover:bg-red-100">
          X
        </div>
      <% [:x, true] -> %>
        <div class="p-5 text-xl border-black border-2 text-center h-full w-full bg-green-200 hover:bg-red-100">
          X
        </div>
      <% [:o, false] -> %>
        <div class="p-5 text-xl border-black border-2 text-center h-full w-full hover:bg-red-100">
          O
        </div>
      <% [:o, true] -> %>
        <div class="p-5 text-xl border-black border-2 text-center h-full w-full bg-red-200 hover:bg-red-100">
          O
        </div>
    <% end %>
    """
  end

  def handle_event("play-again", _params, socket) do
    Lv.GameServer.release(socket.assigns.server)
    {:ok, new_server} = Lv.GameServer.start(module: Lv.TicTacToe.Game, module_arg: [])
    {:noreply, assign(socket, game: Lv.GameServer.get_game(new_server), server: new_server)}
  end

  def handle_event(
        "mark",
        %{"row" => row, "col" => col},
        %{assigns: %{multiplayer: true, marker: marker}} = conn
      ) do
    coords = [row, col] |> Enum.map(&String.to_integer/1)
    game = GameServer.player_move_multi(conn.assigns.server, {coords, marker}, self())
    IO.inspect(game.winner, label: "winner value")
    IO.inspect(marker, label: "marker value")
    {:noreply, assign(conn, state: "opponent-move", game: game, turn_count: conn.assigns.turn_count + 1, turn_timer: @turn_time)}
  end

  def handle_event("mark", %{"row" => row, "col" => col}, socket) do
    coords = [row, col] |> Enum.map(&String.to_integer/1)
    updated_game = Lv.GameServer.player_move_single(socket.assigns.server, coords)
    {:noreply, assign(socket, game: updated_game)}
  end

  def handle_event("kill-lobby", _params, socket) do
    PubSub.broadcast(Lv.PubSub, "lobbies", {:delete, {:id, socket.assigns.lobby_id}})
    {:noreply, push_navigate(socket, to: ~p"/")}
  end

  def handle_event("resign", _parmas, socket) do
    GameServer.resign_game(socket.assigns.server, self())
    {:noreply, push_navigate(socket, to: ~p"/")}
  end

  def terminate(_reason, socket) do
    if socket.assigns.state in ["started", "opponent-move", "your-move"],
      do: GameServer.resign_game(socket.assigns.server, self())

    if socket.assigns.state == "waiting",
      do: PubSub.broadcast(Lv.PubSub, "lobbies", {:delete, {:id, socket.assigns.lobby_id}})
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
    GenServer.call(pid, {:set_marker, color})
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

  def handle_call({:set_marker, marker}, _caller, socket) do
    {:reply, :ok, assign(socket, marker: marker)}
  end

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
        %{assigns: %{turn_count: turn_count, game: game, server: server, marker: color}} = conn
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
end
