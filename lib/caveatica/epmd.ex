defmodule Caveatica.Epmd do
  use GenServer
  require Logger

  @name :epmd
  @epmd_port 4369
  @caveatica_port 5555

  def start_link(_opts) do
    Logger.info "Caveatica.Epmd.start_link/1"
    GenServer.start_link(__MODULE__, %{}, name: @name)
  end

  @impl true
  def init(_opts) do
    Logger.info "Caveatica.Epmd.init/1"
    Logger.info "Caveatica.Epmd: Starting epmd..."
    System.cmd("epmd", ["-daemon"])
    Logger.info "Caveatica.Epmd: Registering as distributed node..."
    Node.start(:"caveatica@127.0.0.1")

    {:ok, nil}
  end

  @impl true
  def handle_cast(:setup_tunnel, state) do
    Logger.info "Caveatica.Epmd: Creating reverse tunnel to local epmd..."
    # TODO: handle failure
    result_1 = GenServer.call(:connection, {:tcpip_tunnel_from_server, %{from: @epmd_port, to: @epmd_port}})
    Logger.info "result_1: #{inspect(result_1, [pretty: true, width: 0])}"
    Logger.info "Caveatica.Epmd: Creating reverse tunnel to this node..."
    result_2 = GenServer.call(:connection, {:tcpip_tunnel_from_server, %{from: @caveatica_port, to: @caveatica_port}})
    Logger.info "result_2: #{inspect(result_2, [pretty: true, width: 0])}"
    {:noreply, state}
  end
end
