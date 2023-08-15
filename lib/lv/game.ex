defprotocol Lv.Game do
  def play_round(game, spot)
  def mark(game, spot, marker)
  def draw_check(game)
  def win_check(game)
  def winner?(game)
  def draw?(game)
  def markers(game)
  def name(game)
  def random_move(game)
  def possible_moves(game)
  def winning_player(game)
end

defimpl Lv.Game, for: Lv.ConnectFour.Game do
  def mark(game, col, marker) do
    Lv.ConnectFour.Game.mark(game, col, marker)
  end

  def play_round(game, col) do
    Lv.ConnectFour.Game.play_round(game, col)
  end

  def draw_check(game) do
    Lv.ConnectFour.Game.draw_check(game)
  end

  def win_check(game) do
    Lv.ConnectFour.Game.win_check(game)
  end

  def winner?(game) do
    if game.winner, do: true, else: false
  end

  def draw?(game) do
    if game.draw, do: true, else: false
  end

  def markers(_game) do
    [:red, :black]
  end

  def name(_game), do: "connectfour"
  def random_move(game), do: Lv.ConnectFour.Game.open_cols(game) |> Enum.random()
  def possible_moves(game), do: Lv.ConnectFour.Game.open_cols(game)
  def winning_player(%Lv.ConnectFour.Game{winner: nil}), do: nil
  def winning_player(%Lv.ConnectFour.Game{winner: winner}), do: winner
end

defimpl Lv.Game, for: Lv.TicTacToe.Game do
  def mark(game, spot, symbol) do
    Lv.TicTacToe.Game.mark(game, spot, symbol)
  end

  def play_round(game, coords) do
    Lv.TicTacToe.Game.play_round(game, coords)
  end

  def win_check(game) do
    Lv.TicTacToe.Game.winner(game)
  end

  def draw_check(game) do
    Lv.TicTacToe.Game.draw_check(game)
  end

  def winner?(game) do
    if game.winner, do: true, else: false
  end

  def draw?(game) do
    if game.draw, do: true, else: false
  end

  def markers(_game) do
    [:x, :o]
  end

  def name(_game), do: "tictactoe"
  def random_move(game), do: Lv.TicTacToe.Game.free_spaces(game) |> Enum.random() |> elem(0)
  def possible_moves(game) do
    Lv.TicTacToe.Game.free_spaces(game)
    |> Enum.map(& elem(&1, 0))
  end
  def winning_player(%Lv.TicTacToe.Game{winner: nil}), do: nil
  def winning_player(%Lv.TicTacToe.Game{winner: winner}), do: winner
end
