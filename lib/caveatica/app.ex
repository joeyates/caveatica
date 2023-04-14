defmodule Caveatica.App do
  @moduledoc false

  use Application
  require Logger

  def start(_type, _args) do
    Logger.info "Caveatica.App.start/2"
    children = [
      Caveatica.Epmd,
      Caveatica.Connection
    ]

    {:ok, pid} = Supervisor.start_link(children, strategy: :one_for_one)

    {:ok, pid}
  end
end
