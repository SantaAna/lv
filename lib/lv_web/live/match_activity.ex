defmodule LvWeb.MatchActivity do
  use LvWeb, :live_view
  alias Lv.MatchCache
  alias Phoenix.PubSub

  def mount(_params, _session, socket) do
    matches = MatchCache.get_matches()
    PubSub.subscribe(Lv.PubSub, "match_results")
    IO.inspect(matches)

    socket
    |> assign(:update, false)
    |> stream(:matches, matches, at: 0, limit: 10)
    |> then(&{:ok, &1})
  end

  def render(assigns) do
    ~H"""
    <h1>Recent Matches</h1>
    <table class="table-auto w-[40rem] mt-11 sm:w-full">
      <thead class="text-sm text-left leading-6 text-zinc-500">
        <tr>
          <th class="p-0 pr-6 pb-4 font-normal">Player 1</th>
          <th class="p-0 pr-6 pb-4 font-normal">Player 2</th>
          <th class="p-0 pr-6 pb-4 font-normal">Game</th>
          <th class="p-0 pr-6 pb-4 font-normal">Result</th>
        </tr>
      </thead>
      <tbody
        phx-update="stream"
        id="match"
        class="relative divide-y divide-zinc-100 border-t border-zinc-200 text-sm leading-6 text-zinc-700"
      >
        <tr
          :for={{dom_id, match} <- @streams.matches}
          id={dom_id}
          phx-mounted={if @update, do: JS.add_class("attentionGreen")}
        >
          <td class="relative p-0">
            <div class="block py-4 pr-6">
              <span class="absolute -inset-y-px right-0 -left-4 group-hover:bg-zinc-50 sm:rounded-l-xl" />
              <span class="relative">
                <%= match.first_player_name %>
              </span>
            </div>
          </td>
          <td class="relative p-0">
            <div class="block py-4 pr-6">
              <span class="absolute -inset-y-px right-0 -left-4 group-hover:bg-zinc-50 sm:rounded-l-xl" />
              <span class="relative">
                <%= match.second_player_name %>
              </span>
            </div>
          </td>
          <td class="relative p-0">
            <div class="block py-4 pr-6">
              <span class="absolute -inset-y-px right-0 -left-4 group-hover:bg-zinc-50 sm:rounded-l-xl" />
              <span class="relative">
                <%= match.game %>
              </span>
            </div>
          </td>
          <td class="relative p-0">
            <div class="block py-4 pr-6">
              <span class="absolute -inset-y-px right-0 -left-4 group-hover:bg-zinc-50 sm:rounded-l-xl" />
              <span class="relative">
                <%= case [match.winner_id, match.second_player_id, match.first_player_id] do
                  [nil, _, _] -> "Draw"
                  [w, w, _] -> "#{match.second_player_name} won"
                  [w, _, w] -> "#{match.first_player_name} won"
                end %>
              </span>
            </div>
          </td>
        </tr>
      </tbody>
    </table>
    """
  end

  def handle_info({:match_result, match}, socket) do
    socket
    |> assign(:update, true)
    |> stream_insert(:matches, match, at: 0, limit: 10)
    |> then(&{:noreply, &1})
  end
end
