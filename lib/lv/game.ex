defprotocol Lv.Game do
  def play_round(game, spot)
  def mark(game, spot, marker)
  def draw_check(game)
  def win_check(game)
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
end
