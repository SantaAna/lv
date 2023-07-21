defmodule LvWeb.RockPaperScissors do
  use LvWeb, :live_view
  @choices ["Rock", "Paper", "Scissors"]
  @beats %{
    "Rock" => "Scissors",
    "Paper" => "Rock",
    "Scissors" => "Paper"
  }

  def mount(_params, _session, socket) do
    {:ok, assign(socket, player_choice: nil, computer_choice: nil)}
  end

  def render(assigns) do
    ~H"""
    <h1>Rock Paper Scissors</h1>
    <%= case result(assigns) do %>
      <% :computer_wins  -> %>
        <.computer_win_message computer_choice={@computer_choice} player_choice={@player_choice} />
      <% :player_wins  -> %>
        <.player_win_message computer_choice={@computer_choice} player_choice={@player_choice} />
      <% :draw  -> %>
        <.draw_message computer_choice={@computer_choice} player_choice={@player_choice} />
      <% _  -> %>
        <div></div>
    <% end %>
    <h2 class="mt-10"> Choose your throw </h2>
    <div class="flex flex-row gap-5">
      <.choice_button :for={title <- ~w(Rock Paper Scissors)} title={title} />
    </div>
    """
  end

  def computer_win_message(assigns) do
    ~H"""
    <h2 class="text-red-500">You Lose</h2>
    <p>The computer played <%= @computer_choice %> and you played <%= @player_choice %></p>
    """
  end

  def player_win_message(assigns) do
    ~H"""
    <h2 class="text-green-500">You Win</h2>
    <p>The computer played <%= @computer_choice %> and you played <%= @player_choice %></p>
    """
  end

  def draw_message(assigns) do
    ~H"""
    <h2 class="text-yellow-700">Draw</h2>
    <p>The computer played <%= @computer_choice %> and you played <%= @player_choice %></p>
    """
  end

  def choice_button(assigns) do
    ~H"""
    <button phx-click={@title} class="bg-cyan-400 p-3 rounded-md hover:bg-cyan-200">
      <%= @title %>
    </button>
    """
  end

  def handle_event("Rock", _params, socket) do
    {:noreply, assign(socket, player_choice: "Rock", computer_choice: computer_play())}
  end

  def handle_event("Paper", _params, socket) do
    {:noreply, assign(socket, player_choice: "Paper", computer_choice: computer_play())}
  end

  def handle_event("Scissors", _params, socket) do
    {:noreply, assign(socket, player_choice: "Scissors", computer_choice: computer_play())}
  end

  def computer_play() do
    Enum.random(@choices)
  end

  def result(%{player_choice: pc, computer_choice: cc}) when pc != nil and cc != nil do
    case [Map.get(@beats, pc) == cc, Map.get(@beats, cc) == pc] do
      [true, _] -> :player_wins
      [_, true] -> :computer_wins
      _ -> :draw
    end
  end

  def result(_), do: nil
end
