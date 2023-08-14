defmodule Lv.LobbyTest do
  use ExUnit.Case 
  alias Lv.Lobby
  alias Lv.GameServer

  @game_player_modules [%{game: Lv.ConnectFour.Game, player: LvWeb.ConnectFour}, %{game: Lv.TicTacToe.Game, player: LvWeb.TicTacToe}]

  test "new creates lobby with valid game server" do
    id = Lv.LobbyServer.get_id()
    game_start_info = Enum.random(@game_player_modules)
    l = Lobby.new(id, game_start_info.game, game_start_info.player)
    assert Process.alive?(l.game_server) == true
    assert l.status == :waiting_for_opponent
    assert l.game == Lv.Game.name(GameServer.get_game(l.game_server))
  end
end
