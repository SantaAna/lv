defmodule Lv.Lobby do
  defstruct [:player1_pid, :player2_pid, :game_server, :status, :id, :game]

  alias Lv.GameServer

  @type status :: :in_progress | :completed | :waiting_for_opponent

  @type t :: %__MODULE__{
          game_server: pid,
          status: status, 
          id: integer | nil,
          game: String.t()
        }


  def new(id, module, player) when is_integer(id) do
    {:ok, server} = GameServer.start([module: module, player: player, module_arg: []])
    %__MODULE__{
      id: id,
      game_server: server,
      status: :waiting_for_opponent,
      game: Lv.Game.name(GameServer.get_game(server))
    }
  end
end
