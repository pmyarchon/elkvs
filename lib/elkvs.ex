defmodule Elkvs do
  use Application
  require Logger

  def start(_type, _args) do
    Logger.debug("Elkvs started...", [])
    web_port = Application.get_env(:elkvs, :web_port)
    children = [Plug.Adapters.Cowboy.child_spec(:http, Router, [], port: web_port), Storage]
    Supervisor.start_link(children, [strategy: :one_for_one, name: Elkvs.Supervisor])
  end
end
