defmodule LvWeb.ConnectFourComponents do
  use LvWeb, :html

  slot :inner_block, required: true

  def center_all(assigns) do
    ~H"""
    <div class="mx-auto text-center">
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  slot :inner_block, required: true

  def center_board(assigns) do
    ~H"""
    <div class="flex flex-row justify-center">
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  slot :inner_block, required: true

  def single_player_display(assigns) do
    ~H"""
    <.center_all>
      <.pick_banner game={@game} color={@color} />
        <.center_board>
          <%= render_slot(@inner_block) %>
        </.center_board>
      <.link_button :if={@game.winner || @game.draw} phx-click="play-again">
        Play Again
      </.link_button>
    </.center_all>
    """
  end

  slot :inner_block, required: true

  def multiplayer_game_over(assigns) do
    ~H"""
    <div class="mx-auto text-center">
      <.pick_banner game={@game} color={@color} />
      <div class="flex flex-row justify-center">
        <%= render_slot(@inner_block) %>
      </div>
      <.link navigate={~p"/"}>
        <.link_button>
          Return to Lobby
        </.link_button>
      </.link>
    </div>
    """
  end

  # slot :inner_block, required: true
  # attr :rest, :global

  # def link_button(assigns) do
  #   ~H"""
  #   <button
  #     class="rounded-md m-3 px-3 py-3 text-gray-50 bg-black font-bold cursor-pointer tracking-wider hover:bg-gray-700 transition-all"
  #     {@rest}
  #   >
  #     <%= render_slot(@inner_block) %>
  #   </button>
  #   """
  # end

  def pick_banner(assigns) do
    ~H"""
    <%= cond do %>
      <% @game.draw  -> %>
        <h2 class="text-yellow-300 text-lg font-semibold">Draw!</h2>
      <% @game.winner == @color -> %>
        <h2 class="text-emerald-500 text-lg font-semibold">You Win!</h2>
      <% @game.winner == nil -> %>
        <h2></h2>
      <% true -> %>
        <h2 class="text-red-600 text-lg font-semibold">You Lose!</h2>
    <% end %>
    """
  end

  slot :inner_block, required: true

  def multiplayer_opp_resigned(assigns) do
    ~H"""
    <.center_all>
      <h2 class="text-emerald-500 text-lg font-semibold">You Win!</h2>
      <h3>Your opponent resigned</h3>
      <.center_board>
        <%= render_slot(@inner_block) %>
      </.center_board>
      <.link navigate={~p"/"}>
        <.link_button>
          Return to Lobby
        </.link_button>
      </.link>
    </.center_all>
    """
  end

  slot :inner_block, required: true

  def multiplayer_your_turn(assigns) do
    ~H"""
    <.center_all>
      <div class="flex w-1/2 mx-auto justify-evenly attentionGreen rounded-md">
        <h2 class="font-semibold">Make Your Move</h2>
        <h2> Seconds Left: <%= @turn_timer %> </h2> 
      </div>
      <.center_board>
        <%= render_slot(@inner_block) %>
      </.center_board>
      <.negative_button phx-click="resign">Resign Game</.negative_button>
    </.center_all>
    """
  end

  slot :inner_block, required: true

  def multiplayer_opp_turn(assigns) do
    ~H"""
    <.center_all>
      <h2 class="font-semibold">Waiting for opponent to make move</h2>
      <.center_board>
        <%= render_slot(@inner_block) %>
      </.center_board>
      <.negative_button phx-click="resign">Resign Game</.negative_button>
    </.center_all>
    """
  end

  def multiplayer_wait(assigns) do
    ~H"""
    <div class="flex flex-col justify-items-center mx-auto text-center w-1/2">
      <h2 class="mb-4 text-lg font-bold">Waiting for opponent to join</h2>
      <.negative_button phx-click="kill-lobby">
        Leave Lobby
      </.negative_button>
    </div>
    """
  end

  slot :inner_block, required: true
  attr :rest, :global

  def negative_button(assigns) do
    ~H"""
    <button
      class="m-3 rounded-md px-3 py-3 text-gray-50 bg-red-700 font-bold cursor-pointer tracking-wider hover:bg-red-500 transition-all"
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  slot :inner_block, required: true

  def multiplayer_start(assigns) do
    ~H"""
    <.center_all>
      <h2 class="font-semibold">Game is Starting</h2>
      <.center_board>
        <%= render_slot(@inner_block) %>
      </.center_board>
    </.center_all>
    """
  end

  def connect_four_board(assigns) do
    ~H"""
    <div class="flex flex-row-reverse border-yellow-400 border-4 rounded-md w-min mt-3">
      <.connect_four_row
        :for={{col, col_num} <- @cols}
        col={col}
        col_num={col_num}
        interact={@interact}
      />
    </div>
    """
  end

  def connect_four_row(assigns) do
    ~H"""
    <div class={"flex flex-col #{if @interact, do: "group", else: ""}"} phx-value-col={@col_num} phx-click={@interact && "drop-piece"}>
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
