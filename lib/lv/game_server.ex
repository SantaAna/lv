defmodule Lv.GameServer do
  use GenServer
  require Logger
  alias Phoenix.PubSub

  # client side
  def start(opts \\ []) do
    GenServer.start(__MODULE__, opts)
  end

  def get_game(pid) do
    GenServer.call(pid, :get_game)
  end

  def player_join(pid, player_pid, user_info) do
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
     %{
       game: opts[:module].new(opts[:module_arg]),
       player1_pid: nil,
       player2_pid: nil,
       player: opts[:player]
     }}
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
    [first_player_pid, second_player_pid] = Enum.shuffle([p1_pid, p2_pid])
    [first_marker, second_marker] = Lv.Game.markers(game)

    player.set_marker(first_player_pid, first_marker)
    player.set_marker(second_player_pid, second_marker)
    player.change_state(second_player_pid, "opponent-move")
    player.take_turn(first_player_pid, game)

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

  def handle_call({:player_move_multi, _, _} = message, _from, state) do
    state =
      state
      |> whose_turn(message)
      |> mark_and_check(message)
      |> execute_if(&game_over?/1, &game_over_updates/1)
      |> execute_if(&(not game_over?(&1)), &game_continue_updates/1)
      |> execute_if(&game_over?/1, &schedule_kill/1)

    {:reply, state.game, state}
  end

  @spec execute_if(term, (term -> boolean), (term -> term)) :: term
  defp execute_if(arg, con, fun) do
    if con.(arg) do
      fun.(arg)
    else
      arg
    end
  end

  defp schedule_kill(state) do
    Process.send_after(self(), :shutdown, 1000)
    state
  end

  defp game_continue_updates(state) do
    state.player.take_turn(state.next_player_pid, state.game)
    state
  end

  @spec game_over?(map) :: boolean
  defp game_over?(state) do
    Lv.Game.winner?(state.game) || Lv.Game.draw?(state.game)
  end

  defp game_over_updates(state) do
    state.player.change_state(state.player_pid, "game-over")
    state.player.change_state(state.next_player_pid, "game-over")
    state.player.set_game(state.next_player_pid, state.game)

    Lv.Matches.record_match_result(
      state.player_info.id,
      state.next_player_info.id,
      Lv.Game.name(state.game),
      Lv.Game.draw?(state.game)
    )
    PubSub.broadcast(Lv.PubSub, "match_results", {:match_result, %{draw: Lv.Game.draw?(state.game), game: Lv.Game.name(state.game), winner_id: state.player_info.id, loser_id: state.next_player_info.id}})

    state
  end

  @spec mark_and_check(map, tuple) :: map
  defp mark_and_check(state, {_, {spot, marker}, _}) do
    Map.update!(state, :game, fn game ->
      game
      |> Lv.Game.mark(spot, marker)
      |> Lv.Game.win_check()
      |> Lv.Game.draw_check()
    end)
  end

  @spec whose_turn(map, tuple) :: map
  defp whose_turn(state, {_, _, player_pid}) do
    if state.player1_pid == player_pid do
      state
      |> Map.put(:next_player_pid, state.player2_pid)
      |> Map.put(:player_pid, state.player1_pid)
      |> Map.put(:player_info, state.player1_info)
      |> Map.put(:next_player_info, state.player2_info)
    else
      state
      |> Map.put(:next_player_pid, state.player1_pid)
      |> Map.put(:player_pid, state.player2_pid)
      |> Map.put(:player_info, state.player2_info)
      |> Map.put(:next_player_info, state.player1_info)
    end
  end

  @impl true
  def handle_call({:add_player, player_pid, user_info}, _, %{player1_pid: nil} = state) do
    state =
      state
      |> Map.put(:player1_pid, player_pid)
      |> Map.put(:player1_info, user_info)

    {:reply, :ok, state}
  end

  def handle_call({:add_player, player_pid, user_info}, _, %{player2_pid: nil} = state) do
    state =
      state
      |> Map.put(:player2_pid, player_pid)
      |> Map.put(:player2_info, user_info)

    {:reply, :ok, state}
  end

  def handle_call({:add_player, _}, _, state) do
    {:reply, {:error, "no free player slot"}, state}
  end
end
