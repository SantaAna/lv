defmodule Lv.Wordle.Game do
  @words File.read!("./priv/wordle/words.txt")
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

  @doc """
  Creates a new Worlde struct.
  """
  @spec new() :: t
  def new() do
    word = random_word()
    IO.puts word
    %__MODULE__{
      winning_word: word,
      player_guess: nil,
      feed_back: [],
      win: false,
      lose: false,
      max_guesses: 5
    }
  end
  
  @doc """
  Processes a game round given the current game struct and player input.
  Will check whether the game is won or lost.
  """
  @spec play_round(t, String.t) :: t
  def play_round(%__MODULE__{} = game, player_input) do
    game
    |> feedback(player_input)
    |> win?()
    |> advance_round()
    |> lose?()
  end

  @spec advance_round(t) :: t
  defp advance_round(%__MODULE__{} = game), do: Map.update!(game, :round_count, &(&1 + 1))

  @spec win?(t) :: t
  defp win?(%__MODULE__{feed_back: feedback, lose: false} = game) do
    if Enum.all?(List.first(feedback), &(elem(&1,0) == :green)) do
      Map.put(game, :win, true)
    else
      game
    end
  end

  defp win?(game), do: game

  @spec lose?(t) :: t
  defp lose?(%__MODULE__{win: false, max_guesses: mg, round_count: rc} = game) when rc > mg,
    do: Map.put(game, :lose, true)

  defp lose?(game), do: game

  @spec feedback(t, String.t()) :: t
  defp feedback(%__MODULE__{winning_word: target_word} = game, guessed_word) do
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

  # marks letters in the correct spot as green
  defp find_greens({target_chars, guessed_chars}) do
    Enum.zip([target_chars, guessed_chars])
    |> Enum.map(fn
      {same, same} -> {nil, :green}
      {tar, guess} -> {tar, guess}
    end)
    |> Enum.unzip()
  end

  # marks letters as yellow until we are out of letter occurences
  defp find_yellows({target_chars, guessed_chars}) do
    Enum.reduce(guessed_chars, {target_chars, []}, fn guess, {target_chars, updated} ->
      if guess in target_chars do
        {List.delete(target_chars, guess), List.insert_at(updated, -1, :yellow)}
      else
        {target_chars, List.insert_at(updated, -1, guess)}
      end
    end)
  end

  # marks any remaining letters as red
  defp find_reds({_target_chars, guessed_chars}) do
    Enum.map(guessed_chars, fn char ->
      if char in [:yellow, :green] do
        char
      else
        :red
      end
    end)
  end

  # gets a random word from the word list
  defp random_word(length \\ 5) do
    @words
    |> String.split("\n")
    |> Enum.map(&String.trim/1)
    |> Enum.filter(&(String.length(&1) == length))
    |> Enum.random()
  end
end
