defmodule LvWeb.HomeLive do
  use LvWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <h1 class="text-2xl mb-3">Would you like to play a game?</h1>
    <p class="mb-3">Pick a game from the list below or the menu bar at the top of the page.</p>
    <.link navigate={~p"/rps"} class="text-xl">Rock Paper Scissors</.link>
    <p>Are you a bad enough paper pusher to push over the computer?</p>
    <p class="mb-3">Prove your the fastest rock slinger in the west.</p>
    <.link navigate={~p"/ttt"} class="text-xl">TicTacToe</.link>
    <p class="mb-3">Play the computer at TicTacToe, but abandon all hope of victory</p>
    <.link navigate={~p"/wordle"} class="text-xl">Wordle</.link>
    <p class="mb-3">Try to guess a five letter word in five tries.  You'll be shown a hint after each try.</p>
    <.link navigate={~p"/connectfour"} class="text-xl">Connect Four</.link>
    <p>Try to connect four before the computer - look out it has some tricks up its circuits.</p>
    """
  end
end
