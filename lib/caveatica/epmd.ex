defmodule Caveatica.Epmd do
  use GenServer
  require Logger

  @name :epmd
  @server_user Application.compile_env!(:caveatica, :server_user)
  @server_fqdn Application.compile_env!(:caveatica, :server_fqdn)
  @ssh_port 22
  @epmd_port 4369
  @caveatica_port 5555
  @max_failed_attempts 10
  @initial_state %{
    status: :disconnected,
    conn: nil,
    attempts: 0,
    backoff: 1000
  }

  def start_link(_opts) do
    Logger.info "Caveatica.Epmd.start_link/1"
    GenServer.start_link(__MODULE__, %{}, name: @name)
  end

  def init(_opts) do
    Logger.info "Caveatica.Epmd.init/1"
    Logger.info "Starting epmd..."
    System.cmd("epmd", ["-daemon"])
    Logger.info "Registering as distributed node..."
    Node.start(:"caveatica@127.0.0.1")

    send(self(), :connect)

    {:ok, @initial_state}
  end

  def handle_call(:reset, _from, state) do
    Logger.info "Received call `:reset`"
    {:reply, {:ok}, @initial_state}
  end

  def handle_cast(:connect, state) do
    Logger.info "Received cast `:connect`"
    {:noreply, connect(state)}
  end

  def handle_info(:connect, state) do
    Logger.info "Received info `:connect`"
    {:noreply, connect(state)}
  end

  def handle_info(:setup_tunnel, %{status: :connected} = state) do
    Logger.info "Creating reverse tunnel to local epmd..."
    :ssh.tcpip_tunnel_from_server(state.conn, '127.0.0.1', @epmd_port, '127.0.0.1', @epmd_port)
    Logger.info "Creating reverse tunnel to this node..."
    :ssh.tcpip_tunnel_from_server(state.conn, '127.0.0.1', @caveatica_port, '127.0.0.1', @caveatica_port)
    {:noreply, state}
  end

  def ssh_disconnected(term) do
    Logger.info("Received SSH disconnect: #{term}")
    {:ok} = GenServer.call(@name, :reset)
    GenServer.cast(@name, :connect)
  end

  defp connect(state) do
    Logger.info "Connecting to control host..."
    case :ssh.connect(String.to_charlist(@server_fqdn), @ssh_port, ssh_config()) do
      {:ok, conn} ->
        Logger.info "Successfully connected"
        send(self(), :setup_tunnel)
        %{state | conn: conn, status: :connected}
      {:error, reason} ->
        Logger.error "Connection failed: #{reason}"
        attempts = state.attempts
        Logger.error "attempts: #{attempts}"
        if attempts < @max_failed_attempts do
          backoff = state.backoff * 2
          Logger.error "Retrying in #{backoff}ms..."
          Process.send_after(self(), :connect, backoff)
          %{state | attempts: attempts + 1, backoff: backoff}
        else
          Logger.error "Giving up - too many failed attempts"
          %{state | attempts: attempts, status: :dead}
        end
    end
  end

  defp ssh_config do
    ssh_key_path = Application.app_dir(:caveatica, "priv")

    [
      user_interaction: false,
      silently_accept_hosts: true,
      user: String.to_charlist(@server_user),
      user_dir: String.to_charlist(ssh_key_path),
      disconnectfun: &ssh_disconnected/1
    ]
  end
end
