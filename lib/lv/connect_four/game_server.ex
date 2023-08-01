defmodule Lv.ConnectFour.GameServer do
  use GenServer
  alias Lv.ConnectFour.Game
  alias LvWeb.ConnectFour, as: Player
  require Logger

  # client side
  def start(opts \\ []) do
    opts = Keyword.put_new(opts, :computer_difficulty, :perfect)
    GenServer.start(__MODULE__, opts)
  end

  def player_join(pid, player_pid) do
    GenServer.call(pid, {:add_player, player_pid})
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
    {:ok, %{game: Game.new(opts), player1_pid: nil, player2_pid: nil}}
  end

  @impl true
  def handle_info(:shutdown, state) do
    Logger.info("GameServer process #{inspect(self())} stopped normally")
    {:stop, :normal, state}
  end

  @impl true
  def handle_info(:first_turn, %{player1_pid: p1_pid, player2_pid: p2_pid, game: game} = state) do
    first_player = Enum.random([:player1_pid, :player2_pid])

    case first_player do
      :player1_pid ->
        Player.set_color(p1_pid, :red)
        Player.set_color(p2_pid, :black)
        Player.change_state(p2_pid, "opponent-move")
        Player.take_turn(p1_pid, game)

      :player2_pid ->
        Player.set_color(p1_pid, :black)
        Player.set_color(p2_pid, :red)
        Player.change_state(p1_pid, "opponent-move")
        Player.take_turn(p2_pid, game)
    end

    {:noreply, state}
  end

  @impl true
  def handle_cast(:start_game, %{player1_pid: p1_pid, player2_pid: p2_pid} = state) do
    [p1_pid, p2_pid]
    |> Enum.each(&Player.change_state(&1, "started"))

    Process.send_after(self(), :first_turn, 1_000)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:resign, resigning_player_pid}, %{player1_pid: resigning_player_pid, player2_pid: other_player_pid} = state) do
    Player.change_state(other_player_pid, "opp-resigned") 
    Process.send_after(self(), :shutdown, 1000)  
    {:noreply, state}
  end

  def handle_cast({:resign, resigning_player_pid}, %{player1_pid: other_player_pid, player2_pid: resigning_player_pid} = state) do
    Player.change_state(other_player_pid, "opp-resigned") 
    Process.send_after(self(), :shutdown, 1000)  
    {:noreply, state}
  end

  @impl true
  def handle_call({:player_move_single, column}, _from, %{game: game} = state) do
    updated_game = Game.play_round(game, column)
    {:reply, updated_game, Map.put(state, :game, updated_game)}
  end

  @impl true
  def handle_call(
        {:player_move_multi, {col, color}, player_pid},
        _from,
        %{player1_pid: player_pid, player2_pid: next_player_pid, game: game} = state
      ) do
    updated_game =
      Game.mark(game, col, color)
      |> Game.draw_check()
      |> Game.win_check()

    cond do
      updated_game.draw || updated_game.winner ->
        Player.change_state(player_pid, "game-over")
        Player.change_state(next_player_pid, "game-over")
        Player.set_game(next_player_pid, updated_game)
        Process.send_after(self(), :shutdown, 1000)
        {:reply, updated_game, Map.put(state, :game, updated_game)}
      true ->
        Player.take_turn(next_player_pid, updated_game)
        {:reply, updated_game, Map.put(state, :game, updated_game)}
    end
  end

  def handle_call(
        {:player_move_multi, {col, color}, player_pid},
        _from,
        %{player1_pid: next_player_pid, player2_pid: player_pid, game: game} = state
      ) do
    updated_game =
      Game.mark(game, col, color)
      |> Game.draw_check()
      |> Game.win_check()
    cond do
      updated_game.draw || updated_game.winner ->
        Player.change_state(player_pid, "game-over")
        Player.change_state(next_player_pid, "game-over")
        Player.set_game(next_player_pid, updated_game)
        Process.send_after(self(), :shutdown, 1000)
        {:reply, updated_game, Map.put(state, :game, updated_game)}
      true ->
        Player.take_turn(next_player_pid, updated_game)
        {:reply, updated_game, Map.put(state, :game, updated_game)}
    end
  end

  @impl true
  def handle_call({:add_player, player_pid}, _, %{player1_pid: nil} = state) do
    {:reply, :ok, Map.put(state, :player1_pid, player_pid)}
  end

  def handle_call({:add_player, player_pid}, _, %{player2_pid: nil} = state) do
    {:reply, :ok, Map.put(state, :player2_pid, player_pid)}
  end

  def handle_call({:add_player, _}, _, state) do
    {:reply, {:error, "no free player slot"}, state}
  end
end
