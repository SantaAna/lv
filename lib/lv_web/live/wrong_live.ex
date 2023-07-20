defmodule LvWeb.WrongLive do
  use LvWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       score: 0,
       message: "make a guess...",
       target: Enum.random(1..10),
       reset_pending: false
     )}
  end

  def render(assigns) do
    ~H"""
    <h1>Your Score: <%= @score %></h1>
    <h2>
      <%= @message %>
    </h2>
    <h2>
      <%= if @reset_pending do %>
        <button phx-click="play-again">Play Again</button>
      <% else %>
        <%= for n <- 1..10 do %>
          <.link href="#" phx-click="guess" phx-value-number={n}>
            <%= n %>
          </.link>
        <% end %>
      <% end %>
    </h2>
    """
  end

  def handle_event("play-again", _, socket) do
    {
      :noreply,
      assign(socket, message: "make a guess...", target: Enum.random(1..10), reset_pending: false)
    }
  end

  def handle_event("guess", %{"number" => guess}, socket) do
    cond do
      String.to_integer(guess) == socket.assigns.target ->
        message = "Your guess was correct!"
        updated_score = socket.assigns.score + 1

        {
          :noreply,
          assign(
            socket,
            message: message,
            score: updated_score,
            reset_pending: true
          )
        }

      true ->
        message = "Your guess was: #{guess}, that's wrong! Try again."
        updated_score = socket.assigns.score - 1

        {
          :noreply,
          assign(
            socket,
            message: message,
            score: updated_score
          )
        }
    end
  end
end
