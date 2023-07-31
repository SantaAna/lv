defmodule LvWeb.ConnectFourComponents do
  use Phoenix.Component  
  alias Lv.ConnectFour.Game

  def multiplayer_wait(assigns) do
  ~H"""
        <h2>Waiting for opponent to join</h2>
          <button phx-click="kill-lobby">
            Leave Lobby
          </button>
  """
  end
  
  slot :inner_block, required: true 
  def multiplayer_start(assigns) do
    ~H"""
        <h2>Game is starting</h2>
        <%= render_slot(@inner_block) %>
    """
  end

  def connect_four_board(assigns) do
    ~H"""
    <div class="flex flex-row-reverse border-yellow-400 border-4 rounded-md w-min">
      <.connect_four_row
        :for={{col, col_num} <- Game.get_cols(@game)}
        col={col}
        col_num={col_num}
        interact={@interact}
      />
    </div>
    """
  end

  def connect_four_row(assigns) do
    ~H"""
    <div class="flex flex-col group" phx-value-col={@col_num} phx-click={@interact && "drop-piece"}>
      <.connect_four_square :for={marker <- Enum.chunk_every(@col, 2, 1)} marker={marker} } />
    </div>
    """
  end

  def connect_four_square(%{marker: [:red, _]} = assigns),
    do: Map.put(assigns, :marker, [:red]) |> connect_four_square()

  def connect_four_square(%{marker: [:red]} = assigns) do
    ~H"""
    <div class="flex flex-row justify-center items-center h-10 w-10 bg-yellow-400">
      <div class="h-9 w-9 rounded-full bg-red-700"></div>
    </div>
    """
  end

  def connect_four_square(%{marker: [:black, _]} = assigns),
    do: Map.put(assigns, :marker, [:black]) |> connect_four_square()

  def connect_four_square(%{marker: [:black]} = assigns) do
    ~H"""
    <div class="flex flex-row justify-center items-center h-10 w-10 bg-yellow-400">
      <div class="h-9 w-9 rounded-full bg-black"></div>
    </div>
    """
  end

  def connect_four_square(%{marker: [:blank, :blank]} = assigns) do
    ~H"""
    <div class="flex flex-row justify-center items-center h-10 w-10 bg-yellow-400">
      <div class="h-9 w-9 rounded-full bg-white"></div>
    </div>
    """
  end

  def connect_four_square(%{marker: [:blank, _]} = assigns),
    do: Map.put(assigns, :marker, [:blank]) |> connect_four_square()

  def connect_four_square(%{marker: [:blank]} = assigns) do
    ~H"""
    <div class="flex flex-row justify-center items-center h-10 w-10 bg-yellow-400">
      <div class="h-9 w-9 rounded-full bg-white group-hover:bg-green-200"></div>
    </div>
    """
  end
end
