defmodule LvWeb.TicTacToe do
  use LvWeb, :live_view
  alias Lv.TicTacToe.{Board, Game, ComputerPlayer, ComputerMoveServer}

  def mount(_params, _session, socket) do
    {:ok, assign(socket, game: Game.new())}
  end

  def render(assigns) do
    ~H"""
    <div class="flex justify-center">
      <div>
        <h1 class="text-center text-2xl mb-5">Tic-Tac-Toe</h1>
        <h2 :if={@game.winner == :computer} class="text-red-500 text-2xl text-center mb-2">
          Comptuer Wins!
        </h2>
        <h2 :if={@game.winner == :player} class="text-green-500 text-2xl text-center mb-2">
          You Win!
        </h2>
        <h2 :if={@game.draw} class="text-yellow-500 text-2xl text-center mb-2">Cat's Game!</h2>
        <.board board={@game.board} done={@game.draw || @game.winner} />
        <div class="flex justify-center">
          <button
            :if={@game.draw || @game.winner}
            class="bg-black text-zinc-50 p-4 mt-5 hover:bg-gray-700"
            phx-click="play-again"
          >
            Play Again
          </button>
        </div>
      </div>
    </div>
    """
  end

  def board(assigns) do
    ~H"""
    <div class="grid grid-cols-3 h-52 w-52">
      <%= for x <- 1..3, y <- 1..3 do %>
        <.board_square coord={[x, y]} board={@board} done={@done} />
      <% end %>
    </div>
    """
  end

  def board_square(assigns) do
    ~H"""
    <%= case @board[@coord] do %>
      <% :blank  -> %>
        <%= if @done do %>
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
      <% :x -> %>
        <div class="p-5 text-xl border-black border-2 text-center h-full w-full hover:bg-red-100">
          X
        </div>
      <% :o -> %>
        <div class="p-5 text-xl border-black border-2 text-center h-full w-full hover:bg-red-100">
          O
        </div>
    <% end %>
    """
  end

  def handle_event("play-again", _params, socket) do
    {:noreply, assign(socket, winner: nil, draw: nil, game: Game.new())}
  end

  def handle_event("mark", %{"row" => row, "col" => col}, socket) do
    coords = [row, col] |> Enum.map(&String.to_integer/1)

    player_game =
      Game.mark(socket.assigns.game, coords, :x)
      |> Game.winner()
      |> Game.draw_check()

    if player_game.winner || player_game.draw do
      {
        :noreply,
        assign(socket, game: player_game)
      }
    else
      computer_move = ComputerMoveServer.get_move(player_game)

      {:noreply,
       assign(socket,
         game:
           Game.mark(player_game, computer_move, :o)
           |> Game.winner()
           |> Game.draw_check()
       )}
    end
  end
end
