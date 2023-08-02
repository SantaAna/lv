defprotocol Lv.Game do
  def play_round(game, spot)
  def mark(game, spot, marker)
  def draw_check(game)
  def win_check(game)
  def winner?(game)
  def draw?(game)
  def markers(game)
  def name(game)
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
    game.winner   
  end
  def draw?(game) do
    game.draw
  end
  def markers(_game) do
    [:red, :black]
  end
  def name(_game), do: "connectfour"
end

defimpl Lv.Game, for: Lv.TicTacToe.Game  do
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
    game.winner
  end
  def draw?(game) do
    game.draw
  end
  def markers(_game) do
    [:x, :o]
  end
  def name(_game), do: "tictactoe"
end
