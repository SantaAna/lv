defmodule LvWeb.Wordle do
  use LvWeb, :live_view
  alias Lv.Wordle.Game

  def mount(_param, _session, socket) do
    {:ok, assign(socket, invalid_reason: nil, game: Game.new())}
  end

  def render(assigns) do
    ~H"""
    <h1>Welcome to Wordle</h1>
    <p :if={@invalid_reason == :too_short} class="text-red-500 text-lg">Your guess is too short!</p>
    <p :if={@invalid_reason == :too_long} class="text-red-500 text-lg">Your guess is too long!</p>
    <p :if={@game.win} class="text-green-500 text-lg">You Win!</p>
    <p :if={@game.lose} class="text-red-500 text-lg">
      You Lose! The word was: <%= @game.winning_word %>
    </p>
    <form :if={!@game.lose && !@game.win} phx-submit="guess">
      <div class="mb-5">
        <label for="player-input"></label>
        <input type="text" name="player-input" />
      </div>
      <button type="submit">Guess</button>
    </form>
    <button :if={@game.win || @game.lose} phx-click="play-again">Play Again</button>
    <div :for={word <- @game.feed_back}>
      <.feedback_word word={word} />
    </div>
    """
  end

  def feedback_word(assigns) do
    ~H"""
    <%= for {color, letter} <- @word do %>
      <span :if={color == :red} class="text-red-400"><%= letter %></span>
      <span :if={color == :yellow} class="text-yellow-400"><%= letter %></span>
      <span :if={color == :green} class="text-green-400"><%= letter %></span>
    <% end %>
    """
  end

  def feedback_letter(assigns) do
    ~H"""
    <span :if={assigns.color == :red} class="text-red-400"><%= @assigns.letter %></span>
    <span :if={assigns.color == :yellow} class="text-yellow-400"><%= @assigns.letter %></span>
    <span :if={assigns.color == :green} class="text-green-400"><%= @assigns.letter %></span>
    """
  end

  def handle_event("play-again", _params, socket) do
    {:noreply, assign(socket, game: Game.new(), invalid_reason: nil)}
  end

  def handle_event("guess", %{"player-input" => player_input}, socket) do
    case String.length(player_input) do
      l when l < 5 ->
        {:noreply, assign(socket, invalid_reason: :too_short)}

      l when l > 5 ->
        {:noreply, assign(socket, invalid_reason: :too_long)}

      _ ->
        game =
          socket.assigns.game
          |> Game.feedback(player_input)
          |> Game.win?()
          |> Game.advance_round()
          |> Game.lose?()

        {:noreply, assign(socket, game: game, invalid_reason: nil)}
    end
  end
end
