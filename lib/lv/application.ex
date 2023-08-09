defmodule Lv.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      LvWeb.Telemetry,
      # Start the Ecto repository
      Lv.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: Lv.PubSub},
      # Start Finch
      {Finch, name: Lv.Finch},
      # Start the Endpoint (http/https)
      LvWeb.Endpoint,
      # Start a worker by calling: Lv.Worker.start_link(arg)
      # {Lv.Worker, arg}
      {Lv.TicTacToe.ComputerMoveServer, []},
      {Lv.LobbyServer, []},
      {Lv.MatchCache, []}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Lv.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    LvWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
