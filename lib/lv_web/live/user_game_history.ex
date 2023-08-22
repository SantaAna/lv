defmodule LvWeb.UserGameHistory do
  use LvWeb, :live_view

  def mount(_param, session, socket) do
    user = Lv.Accounts.get_user_by_session_token(session["user_token"])

    if connected?(socket) do
      # TODO: factor this out to context so it can be tested seperately
      user_id = user.id

      matches =
        Lv.Matches.matches_played_by_user(user_id)
        |> Enum.map(fn
          %{
            winner_id: nil,
            first_player_id: ^user_id,
            second_player_name: opponent_name,
            game: game
          } ->
            %{
              game: game,
              opponent_name: opponent_name,
              result: "draw"
            }

          %{
            winner_id: nil,
            second_player_id: ^user_id,
            first_player_name: opponent_name,
            game: game
          } ->
            %{
              game: game,
              opponent_name: opponent_name,
              result: "draw"
            }

          %{
            winner_id: ^user_id,
            second_player_id: ^user_id,
            first_player_name: opponent_name,
            game: game
          } ->
            %{
              game: game,
              opponent_name: opponent_name,
              result: "win"
            }

          %{
            winner_id: ^user_id,
            first_player_id: ^user_id,
            second_player_name: opponent_name,
            game: game
          } ->
            %{
              game: game,
              opponent_name: opponent_name,
              result: "win"
            }

          %{
            first_player_id: ^user_id,
            second_player_name: opponent_name,
            game: game
          } ->
            %{
              game: game,
              opponent_name: opponent_name,
              result: "loss"
            }

          %{
            second_player_id: ^user_id,
            first_player_name: opponent_name,
            game: game
          } ->
            %{
              game: game,
              opponent_name: opponent_name,
              result: "loss"
            }
        end)

      {:ok, assign(socket, matches: matches, loading: false)}
    else
      {:ok, assign(socket, matches: nil, loading: true)}
    end
  end

  def render(assigns) do
    ~H"""
    <.header>
      Your Match History
      <:subtitle>Ordered newest to oldest</:subtitle>
    </.header>
    <%= if @loading do %>
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
