defmodule LvWeb.ConnectFour do
  use LvWeb, :live_view
  alias Lv.ConnectFour.Game
  alias Lv.ConnectFour.GameServer
  alias Lv.ConnectFour.GameTrackerServer, as: TrackerServer
  alias Phoenix.PubSub

  def mount(%{"lobby_id" => lobby_id, "state" => "joined"}, _session, conn) do
    lobby_id = String.to_integer(lobby_id)
    {:ok, lobby_info} = TrackerServer.get_game(lobby_id)
    PubSub.broadcast(Lv.PubSub, "lobbies", {:delete, {:id, lobby_id}})
    GameServer.player_join(lobby_info.game_server, self())
    GameServer.start_game(lobby_info.game_server)

    {:ok,
     assign(conn,
       game: Game.new(computer_difficulty: :perfect),
       server: lobby_info.game_server,
       state: "started",
       lobby_id: lobby_id,
       multiplayer: true
     )}
  end

  def mount(%{"lobby_id" => lobby_id, "state" => "waiting"} = params, _session, conn) do
    IO.inspect(params, label: "params passsed to mount")
    lobby_id = String.to_integer(lobby_id)
    {:ok, lobby_info} = TrackerServer.get_game(lobby_id)
    GameServer.player_join(lobby_info.game_server, self())

    {:ok,
     assign(conn,
       game: Game.new(computer_difficulty: :perfect),
       server: lobby_info.game_server,
       state: "waiting", lobby_id: lobby_id,
       multiplayer: true
     )}
  end

  def mount(_params, _session, conn) do
    {:ok, server} = GameServer.start()

    {:ok,
     assign(conn,
       game: Game.new(computer_difficulty: :perfect),
       server: server,
       state: "started",
       multiplayer: false,
       color: :red
     )}
  end

  def render(assigns) do
    ~H"""
    <h1>Welcome to Connect Four!</h1>
    <%= case [@state, @multiplayer] do %>
      <% [ "waiting", true ] -> %>
        <h2>Waiting for opponent to join</h2>
          <button phx-click="kill-lobby">
            Leave Lobby
          </button>
      <% ["started", true] -> %>
        <h2>Game is starting</h2>
        <.connect_four_board game={@game} state={@state} interact={false} />
      <% ["opponent-move", true] -> %>
        <h2>Waiting for opponent to make move</h2>
        <.connect_four_board game={@game} state={@state} interact={false} />
        <button phx-click="resign"> Resign Game </button>
      <% ["your-move", true] -> %>
        <h2>Make your move</h2>
        <.connect_four_board game={@game} state={@state} interact={true} />
        <button phx-click="resign"> Resign Game </button>
      <% ["opp-resigned", true] -> %>
        <h2 class="text-emerald-500">You Win!</h2>
        <h3> Your opponent resigned </h3>
        <.connect_four_board game={@game} state={@state} interact={false} />
          <.link navigate={~p"/connectfour_launch"}>
          <button>
            Return to Lobby
          </button>
          </.link>
      <% ["game-over", true] -> %>
        <%= cond do %>
          <% @game.draw  -> %>
            <h2 class="text-yellow-300">Draw!</h2>
          <% @game.winner == @color -> %>
            <h2 class="text-emerald-500">You Win!</h2>
          <% true -> %>
            <h2 class="text-red-600">You Lose!</h2>
        <% end %>
        <.connect_four_board game={@game} state={@state} interact={false} />
          <.link navigate={~p"/connectfour_launch"}>
          <button>
            Return to Lobby
          </button>
          </.link>
      <% [_, false] -> %>
        <%= cond do %>
          <% @game.draw  -> %>
            <h2 class="text-yellow-300">Draw!</h2>
          <% @game.winner == @color -> %>
            <h2 class="text-emerald-500">You Win!</h2>
          <% @game.winner == nil -> %>
            <h2></h2>
          <% true -> %>
            <h2 class="text-red-600">You Lose!</h2>
        <% end %>
        <.connect_four_board game={@game} state={@state} interact={!@game.draw || !@game.winner} />
        <button :if={@game.winner || @game.draw} class="mt-5" phx-click="play-again">
          Play Again
        </button>
    <% end %>
    """
  end

  def connect_four_board(assigns) do
    ~H"""
    <div class="flex flex-row-reverse border-yellow-400 border-4 rounded-md w-min">
      <.connect_four_row
        :for={{col, col_num} <- Game.get_cols(@game)}
        col={col}
        col_num={col_num}
        interact={@interact}
      />
    </div>
    """
  end

  def connect_four_row(assigns) do
    ~H"""
    <div class="flex flex-col group" phx-value-col={@col_num} phx-click={@interact && "drop-piece"}>
      <.connect_four_square :for={marker <- Enum.chunk_every(@col, 2, 1)} marker={marker} } />
    </div>
    """
  end

  def connect_four_square(%{marker: [:red, _]} = assigns),
    do: Map.put(assigns, :marker, [:red]) |> connect_four_square()

  def connect_four_square(%{marker: [:red]} = assigns) do
    ~H"""
    <div class="flex flex-row justify-center items-center h-10 w-10 bg-yellow-400">
      <div class="h-9 w-9 rounded-full bg-red-700"></div>
    </div>
    """
  end

  def connect_four_square(%{marker: [:black, _]} = assigns),
    do: Map.put(assigns, :marker, [:black]) |> connect_four_square()

  def connect_four_square(%{marker: [:black]} = assigns) do
    ~H"""
    <div class="flex flex-row justify-center items-center h-10 w-10 bg-yellow-400">
      <div class="h-9 w-9 rounded-full bg-black"></div>
    </div>
    """
  end

  def connect_four_square(%{marker: [:blank, :blank]} = assigns) do
    ~H"""
    <div class="flex flex-row justify-center items-center h-10 w-10 bg-yellow-400">
      <div class="h-9 w-9 rounded-full bg-white"></div>
    </div>
    """
  end

  def connect_four_square(%{marker: [:blank, _]} = assigns),
    do: Map.put(assigns, :marker, [:blank]) |> connect_four_square()

  def connect_four_square(%{marker: [:blank]} = assigns) do
    ~H"""
    <div class="flex flex-row justify-center items-center h-10 w-10 bg-yellow-400">
      <div class="h-9 w-9 rounded-full bg-white group-hover:bg-green-200"></div>
    </div>
    """
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
    IO.inspect("socket: #{inspect socket}", label: "killing lobby call")
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

  def set_color(pid, color) do
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
