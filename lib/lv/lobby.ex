defmodule Lv.Lobby do
  defstruct [:player1_pid, :player2_pid, :game_server, :status, :id]

  alias Lv.GameServer

  @type status :: :in_progress | :completed | :waiting_for_opponent

  @type t :: %__MODULE__{
          player1_pid: pid,
          player2_pid: pid,
          game_server: pid,
          status: status, 
          id: integer | nil 
        }


  def new(id, module, player) when is_integer(id) do
    {:ok, server} = GameServer.start([module: module, player: player])
    %__MODULE__{
      id: id,
      player1_pid: nil,
      player2_pid: nil,
      game_server: server,
      status: :waiting_for_opponent
    }
  end
end