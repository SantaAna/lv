defmodule LvWeb.ConnectFour do
  use LvWeb, :live_view
  alias Lv.ConnectFour.Game

  def mount(_params, _session, conn) do
    {:ok, assign(conn, game: Game.new(computer_difficulty: :perfect))}
    {:ok, server} = GameServer.start()
    IO.inspect(server)
    {:ok, assign(conn, game: Game.new(computer_difficulty: :perfect), server: server)}
  end

  def render(assigns) do
    ~H"""
    <h1>Welcome to Connect Four!</h1>
    <h2 :if={@game.winner == :player} class="text-emerald-500">You Win!</h2>
    <h2 :if={@game.winner == :computer} class="text-red-600">You Lose!</h2>
    <h2 :if={@game.draw} class="text-yellow-300">Draw!</h2>
    <.connect_four_board game={@game}/>
    <button :if={@game.winner || @game.draw} class="mt-5" phx-click="play-again">Play Again</button>
    """
  end

  def connect_four_board(assigns) do
    ~H"""
    <div class="flex flex-row-reverse border-yellow-400 border-4 rounded-md w-min">
      <.connect_four_row col={col} col_num={col_num} :for={{col, col_num} <- Game.get_cols(@game)}/>
    </div>
    """
  end

  def connect_four_row(assigns) do
    ~H"""
    <div class="flex flex-col group">
      <.connect_four_square marker={marker}} col_num={@col_num} :for={marker <- Enum.chunk_every(@col, 2, 1)}/>
    </div>
    """
  end

  def connect_four_square(%{marker: [:red, _]} = assigns), do: Map.put(assigns, :marker, [:red]) |> connect_four_square()

  def connect_four_square(%{marker: [:red]} = assigns) do
    ~H"""
    <div class="flex flex-row justify-center items-center h-10 w-10 bg-yellow-400">
      <div class="h-9 w-9 rounded-full bg-red-700" phx-value-col={@col_num} phx-click="drop-piece"></div>
    </div>
    """
  end


  def connect_four_square(%{marker: [:black, _]} = assigns), do: Map.put(assigns, :marker, [:black]) |> connect_four_square()

  def connect_four_square(%{marker: [:black]} = assigns) do
    ~H"""
    <div class="flex flex-row justify-center items-center h-10 w-10 bg-yellow-400">
      <div class="h-9 w-9 rounded-full bg-black" phx-value-col={@col_num} phx-click="drop-piece"></div>
    </div>
    """
  end

  def connect_four_square(%{marker: [:blank, :blank]} = assigns) do
    ~H"""
    <div class="flex flex-row justify-center items-center h-10 w-10 bg-yellow-400">
      <div class="h-9 w-9 rounded-full bg-white" phx-value-col={@col_num} phx-click="drop-piece"></div>
    </div>
    """
  end

  def connect_four_square(%{marker: [:blank, _]} = assigns), do: Map.put(assigns, :marker, [:blank]) |> connect_four_square()

  def connect_four_square(%{marker: [:blank]} = assigns) do
    ~H"""
    <div class="flex flex-row justify-center items-center h-10 w-10 bg-yellow-400">
      <div class="h-9 w-9 rounded-full bg-white group-hover:bg-green-200" phx-value-col={@col_num} phx-click="drop-piece"></div>
    </div>
    """
  end

  def handle_event("play-again", _params, conn) do
    {:noreply, assign(conn, game: Game.new(computer_difficulty: :perfect))}
    {:ok, server} = GameServer.start()

    {:noreply,
     assign(conn,
       game: Game.new(computer_difficulty: :perfect),
       server: server
     )}
  end

  def handle_event("drop-piece", %{"col" => col}, conn) do
    play = String.to_integer(col) 
    game = Game.play_round(conn.assigns.game, play)
    play = String.to_integer(col)
    game = GameServer.player_move_single(conn.assigns.server, play)
    if game.winner || game.draw, do: GameServer.release(conn.assigns.server)
    {:noreply, assign(conn, game: game)}
  end
end
