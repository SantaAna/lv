defmodule LvWeb.MatchActivity do
  use LvWeb, :live_view
  alias Lv.MatchCache
  alias Phoenix.PubSub

  def mount(_params, _session, socket) do
    matches = MatchCache.get_matches()
    PubSub.subscribe(Lv.PubSub, "match_results")
    {:ok, stream(socket, :matches, matches, at: 0, limit: 10)}
  end

  def render(assigns) do
    ~H"""
    <h1>Recent Matches</h1>
    <table class="table-auto">
      <tr>
        <th>Player 1</th>
        <th>Player 2</th>
        <th>Game</th>
        <th>Result</th>
      </tr>
      <tbody phx-update="stream" id="match">
        <tr :for={{dom_id, match} <- @streams.matches} id={dom_id} phx-mounted={JS.add_class("attentionGreen")}>
          <td class="px-3"><%= match.winner_name %></td>
          <td class="px-3"><%= match.loser_name %></td>
          <td class="px-3"><%= match.game %></td>
          <td class="px-3"><%= if match.draw, do: "Draw", else: "#{match.winner_name} won" %></td>
        </tr>
      </tbody>
    </table>
    """
  end

  def handle_info({:match_result, match}, socket) do
    {:noreply, stream_insert(socket, :matches, match, at: 0, limit: 10)}
  end

end
