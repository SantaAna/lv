defmodule Lv.Wordle.Game do
  @word_path "./assets/games/words.txt"
  @display_module Application.compile_env(
                    :games,
                    :wordle_display_module,
                    Games.Wordle.Display
                  )

  defstruct [:winning_word, :player_guess, :feed_back, :win, :lose, :max_guesses, round_count: 1]
  @type feedback :: list
  @type t :: %__MODULE__{
          winning_word: String.t(),
          player_guess: String.t() | nil,
          feed_back: feedback | nil,
          win: boolean,
          lose: boolean,
          max_guesses: integer
        }

  # def play() do
  #   Display.welcome()
  #   Display.instructions()
  #   play(%__MODULE__{winning_word: random_word()})
  # end

  # def play(%__MODULE__{round_count: 7} = game), do: @display_module.defeat(game)

  # def play(%__MODULE__{} = game) do
  #   game
  #   |> advance_round()
  #   |> update_player_guess()
  #   |> game_feedback()
  #   |> continue_decision()
  # end

  def new() do
    %__MODULE__{
      winning_word: random_word(),
      player_guess: nil,
      feed_back: [],
      win: false,
      lose: false,
      max_guesses: 5
    }
  end

  def advance_round(%__MODULE__{} = game), do: Map.update!(game, :round_count, &(&1 + 1))

  def game_feedback(%__MODULE__{player_guess: player_guess, winning_word: winning_word} = game) do
    Map.put(game, :feed_back, feedback(winning_word, player_guess))
  end

  @spec random_word(integer) :: String.t()
  def random_word(length \\ 5) do
    File.stream!(@word_path)
    |> Stream.map(&String.trim/1)
    |> Stream.filter(&(String.length(&1) == length))
    |> Enum.random()
  end

  def win?(%__MODULE__{feed_back: feedback, lose: false} = game) do
    if Enum.all?(feedback, &(&1 == :green)) do
      Map.put(game, :win, true)
    else
      game
    end
  end

  def win?(game), do: game

  def lose?(%__MODULE__{win: false, max_guesses: mg, round_count: rc} = game) when rc > mg,
    do: Map.put(game, :lose, true)

  def lose?(game), do: game

  @spec feedback(t, String.t()) :: t
  def feedback(%__MODULE__{winning_word: target_word} = game, guessed_word) do
    feedback =
      {String.graphemes(target_word), String.graphemes(guessed_word)}
      |> find_greens()
      |> find_yellows()
      |> find_reds()
      |> Enum.zip(String.graphemes(guessed_word))

    game
    |> Map.update!(:feed_back, &[feedback | &1])
    |> Map.put(:player_guess, guessed_word)
  end

  def find_greens({target_chars, guessed_chars}) do
    Enum.zip([target_chars, guessed_chars])
    |> Enum.map(fn
      {same, same} -> {nil, :green}
      {tar, guess} -> {tar, guess}
    end)
    |> Enum.unzip()
  end

  def find_yellows({target_chars, guessed_chars}) do
    Enum.reduce(guessed_chars, {target_chars, []}, fn guess, {target_chars, updated} ->
      if guess in target_chars do
        {List.delete(target_chars, guess), List.insert_at(updated, -1, :yellow)}
      else
        {target_chars, List.insert_at(updated, -1, guess)}
      end
    end)
  end

  def find_reds({_target_chars, guessed_chars}) do
    Enum.map(guessed_chars, fn char ->
      if char in [:yellow, :green] do
        char
      else
        :red
      end
    end)
  end
end
