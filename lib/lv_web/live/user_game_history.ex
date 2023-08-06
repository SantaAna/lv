defmodule LvWeb.UserGameHistory do
  use LvWeb, :live_view

  def mount(_param, session, socket) do
    user = Lv.Accounts.get_user_by_session_token(session["user_token"])

    if connected?(socket) do
      #TODO: factor this out to context so it can be tested seperately
      matches =
        Lv.Matches.matches_played_by_user(user.id)
        |> Enum.map(fn match ->
          if match.winner_id == user.id do
            Map.put(match, :opponent_name, match.loser_name)
            |> Map.put(:pot_result, "won")
          else
            Map.put(match, :opponent_name, match.winner_name)
            |> Map.put(:pot_result, "lost")
          end
        end)
        |> Enum.map(fn match -> 
          if match.draw do
            Map.put(match, :result, "draw")
          else
            match
          end
        end)
        |> Enum.map(fn match -> 
          if match.draw do
            match
          else
            Map.put(match, :result, match.pot_result)
          end 
        end)
      {:ok, assign(socket, matches: matches, loading: false)}
    else
      {:ok, assign(socket, matches: nil, loading: true)}
    end
  end

  def render(assigns) do
    ~H"""
    <.header> Your Match History </.header>
    <%=if @loading do %>
      <h2>Loading Match Results</h2>
    <% else %>
      <.table id="Match History" rows={@matches}>
        <:col :let={match} label="game"><%= match.game %></:col>
        <:col :let={match} label="opponent"><%= match.opponent_name %></:col>
        <:col :let={match} label="result"><%= match.result %></:col>
      </.table>
    <% end %>
    """
  end
end
