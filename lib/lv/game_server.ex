defmodule Lv.GameServer do
  use GenServer
  require Logger

  # client side
  def start(opts \\ []) do
    GenServer.start(__MODULE__, opts)
  end

  def get_game(pid) do
    GenServer.call(pid, :get_game)
  end

  def player_join(pid, player_pid, user_info) do
    Logger.log(:warn, "player join called")
    GenServer.call(pid, {:add_player, player_pid, user_info})
  end

  def start_game(pid) do
    GenServer.cast(pid, :start_game)
  end

  def player_move_single(pid, column) do
    GenServer.call(pid, {:player_move_single, column})
  end

  def player_move_multi(pid, move, player_pid) do
    GenServer.call(pid, {:player_move_multi, move, player_pid})
  end

  def resign_game(pid, resigning_player_pid) do
    GenServer.cast(pid, {:resign, resigning_player_pid})
  end

  def release(pid) do
    GenServer.stop(pid, :shutdown)
  end

  # server side
  @impl true
  def init(opts) do
    {:ok,
     %{game: opts[:module].new(opts[:module_arg]), player1_pid: nil, player2_pid: nil, player: opts[:player]}}
  end

  @impl true
  def handle_info(:shutdown, state) do
    {:stop, :normal, state}
  end

  @impl true
  def handle_info(
        :first_turn,
        %{player1_pid: p1_pid, player2_pid: p2_pid, game: game, player: player} = state
      ) do
    first_player = Enum.random([:player1_pid, :player2_pid])
    [first_marker, second_marker] = Lv.Game.markers(game)

    case first_player do
      :player1_pid ->
        player.set_marker(p1_pid, first_marker)
        player.set_marker(p2_pid, second_marker)
        player.change_state(p2_pid, "opponent-move")
        player.take_turn(p1_pid, game)

      :player2_pid ->
        player.set_marker(p1_pid, second_marker)
        player.set_marker(p2_pid, first_marker)
        player.change_state(p1_pid, "opponent-move")
        player.take_turn(p2_pid, game)
    end

    {:noreply, state}
  end

  @impl true
  def handle_cast(
        :start_game,
        %{player1_pid: p1_pid, player2_pid: p2_pid, player: player} = state
      ) do
    [p1_pid, p2_pid]
    |> Enum.each(&player.change_state(&1, "started"))

    Process.send_after(self(), :first_turn, 1_000)
    {:noreply, state}
  end

  @impl true
  def handle_cast(
        {:resign, resigning_player_pid},
        %{player1_pid: resigning_player_pid, player2_pid: other_player_pid, player: player} =
          state
      ) do
    player.change_state(other_player_pid, "opp-resigned")
    Process.send_after(self(), :shutdown, 1000)
    {:noreply, state}
  end

  def handle_cast(
        {:resign, resigning_player_pid},
        %{player1_pid: other_player_pid, player2_pid: resigning_player_pid, player: player} =
          state
      ) do
    player.change_state(other_player_pid, "opp-resigned")
    Process.send_after(self(), :shutdown, 1000)
    {:noreply, state}
  end

  @impl true
  def handle_call({:player_move_single, column}, _from, %{game: game} = state) do
    updated_game = Lv.Game.play_round(game, column)
    {:reply, updated_game, Map.put(state, :game, updated_game)}
  end

  @impl true
  def handle_call(:get_game, _from, %{game: game} = state) do
    {:reply, game, state} 
  end

  @impl true
  def handle_call(
        {:player_move_multi, {col, color}, player_pid},
        _from,
        %{player1_pid: player_pid, player2_pid: next_player_pid, game: game, player: player, player1_info: player_info, player2_info: next_player_info} =
          state
      ) do
    updated_game =
      Lv.Game.mark(game, col, color)
      |> Lv.Game.win_check()
      |> Lv.Game.draw_check()

    cond do
      Lv.Game.winner?(updated_game) || Lv.Game.draw?(updated_game) ->
        player.change_state(player_pid, "game-over")
        player.change_state(next_player_pid, "game-over")
        player.set_game(next_player_pid, updated_game)
        Lv.Matches.record_match_result(player_info.id, next_player_info.id, Lv.Game.name(updated_game), Lv.Game.draw?(updated_game))
        Process.send_after(self(), :shutdown, 1000)
        {:reply, updated_game, Map.put(state, :game, updated_game)}

      true ->
        player.take_turn(next_player_pid, updated_game)
        {:reply, updated_game, Map.put(state, :game, updated_game)}
    end
  end

  def handle_call(
        {:player_move_multi, {col, color}, player_pid},
        _from,
        %{player1_pid: next_player_pid, player2_pid: player_pid, game: game, player: player, player2_info: player_info, player1_info: next_player_info} =
          state
      ) do
    updated_game =
      Lv.Game.mark(game, col, color)
      |> Lv.Game.win_check()
      |> Lv.Game.draw_check()

    cond do
      Lv.Game.winner?(updated_game) || Lv.Game.draw?(updated_game) ->
        player.change_state(player_pid, "game-over")
        player.change_state(next_player_pid, "game-over")
        player.set_game(next_player_pid, updated_game)
        Lv.Matches.record_match_result(player_info.id, next_player_info.id, Lv.Game.name(updated_game), Lv.Game.draw?(updated_game))
        Process.send_after(self(), :shutdown, 1000)
        {:reply, updated_game, Map.put(state, :game, updated_game)}

      true ->
        player.take_turn(next_player_pid, updated_game)
        {:reply, updated_game, Map.put(state, :game, updated_game)}
    end
  end

  @impl true
  def handle_call({:add_player, player_pid, user_info}, _, %{player1_pid: nil} = state) do
    state = state
          |> Map.put(:player1_pid, player_pid)
          |> Map.put(:player1_info, user_info)
    {:reply, :ok, state}
  end

  def handle_call({:add_player, player_pid, user_info}, _, %{player2_pid: nil} = state) do
    state = state
          |> Map.put(:player2_pid, player_pid)
          |> Map.put(:player2_info, user_info)
    {:reply, :ok, state}
  end

  def handle_call({:add_player, _}, _, state) do
    {:reply, {:error, "no free player slot"}, state}
  end
end
