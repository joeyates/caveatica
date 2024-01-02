defmodule Caveatica.App do
  @moduledoc false

  use Application
  require Logger

  @control_socket Application.compile_env!(:caveatica, :control_socket)

  def start(_type, _args) do
    Logger.info "Caveatica.App.start/2"
    children = [
      Picam.Camera,
      Caveatica.Camera,
      {Caveatica.SocketClient, uri: @control_socket}
    ]

    {:ok, pid} = Supervisor.start_link(children, strategy: :one_for_one)

    {:ok, pid}
  end
end
