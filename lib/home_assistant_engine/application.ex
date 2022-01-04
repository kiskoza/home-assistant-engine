defmodule HomeAssistantEngine.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    automations = [
      Automations.SunLogger
    ]

    client = [
      # Starts a worker by calling: HomeAssistantEngine.Worker.start_link(arg)
      {HomeAssistantEngine, {"ws://127.0.0.1:8123/api/websocket", automations}}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: HomeAssistantEngine.Supervisor]
    Supervisor.start_link(client, opts)
  end
end
