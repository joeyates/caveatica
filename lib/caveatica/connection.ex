defmodule Caveatica.Connection do
  use GenServer
  require Logger

  @name :connection
  @server_user Application.compile_env!(:caveatica, :server_user)
  @server_fqdn Application.compile_env!(:caveatica, :server_fqdn)
  @ssh_port 22
  @initial_backoff 1000
  @backoff_factor 1.1
  # 1.1^87 is slightly more than 3600,
  # so we try 86 times before rebooting.
  @max_backoff 3_600_000
  @initial_state %{
    status: :disconnected,
    conn: nil,
    connected_at: nil,
    attempts: 0,
    backoff: @initial_backoff
  }

  def start_link(_opts) do
    Logger.info "Caveatica.Connection.start_link/1"
    GenServer.start_link(__MODULE__, %{}, name: @name)
  end

  @impl true
  def init(_opts) do
    Logger.info "Caveatica.Connection.init/1"

    send(self(), :connect)

    {:ok, @initial_state}
  end

  @impl true
  def handle_call(:reset, _from, _state) do
    Logger.info "Caveatica.Connection.handle_call `:reset`"
    {:reply, {:ok}, @initial_state}
  end

  @impl true
  def handle_call({:send_binary, _opts}, _from, %{status: :disconnected} = state) do
    Logger.info "Caveatica.Connection.handle_call `:send_binary` - while in disconnected state"
    {:reply, {:error, :disconnected}, state}
  end

  @impl true
  def handle_call(:status, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_call({:send_binary, %{binary: binary, pathname: pathname}}, _from, state) do
    Logger.info "Caveatica.Connection.handle_call `:send_binary`"
    size = byte_size(binary)
    Logger.info "Caveatica.Connection.handle_call binary size: #{size}"
    {:ok, channel} = :ssh_sftp.start_channel(state.conn)
    :ok = :ssh_sftp.write_file(channel, pathname, binary)
    :ssh_sftp.stop_channel(channel)
    {:reply, {:ok, :sent}, state}
  end

  @impl true
  def handle_call({:tcpip_tunnel_from_server, _opts}, _from, %{status: :disconnected} = state) do
    Logger.info "Caveatica.Connection.handle_call `:tcpip_tunnel_from_server` - while in disconnected state"
    {:reply, {:error, :disconnected}, state}
  end

  @impl true
  def handle_call({:tcpip_tunnel_from_server, %{from: from, to: to}}, _from, state) do
    Logger.info "Caveatica.Connection.handle_call `:tcpip_tunnel_from_server`"
    result = :ssh.tcpip_tunnel_from_server(state.conn, '127.0.0.1', from, '127.0.0.1', to)
    {:reply, result, state}
  end

  @impl true
  def handle_cast(:connect, state) do
    Logger.info "Caveatica.Connection.handle_cast `:connect`"
    {:noreply, connect(state)}
  end

  @impl true
  def handle_info(:connect, state) do
    Logger.info "Caveatica.Connection.handle_info `:connect`"
    {:noreply, connect(state)}
  end

  def status do
    GenServer.call(@name, :status)
  end

  defp connect(state) do
    Logger.info "Caveatica.Connection: Connecting to control host #{@server_fqdn} on port #{@ssh_port}..."
    case :ssh.connect(String.to_charlist(@server_fqdn), @ssh_port, ssh_config()) do
      {:ok, conn} ->
        Logger.info "Caveatica.Connection: Successfully connected"
        # TODO: this should be done on request, by listeners or pubsub
        GenServer.cast(:epmd, :setup_tunnel)
        %{state | conn: conn, status: :connected, connected_at: DateTime.utc_now()}
      {:error, reason} ->
        Logger.error "Caveatica.Connection: Connection failed: #{reason}"
        attempts = state.attempts
        Logger.error "Caveatica.Connection: attempts: #{attempts}"
        backoff = state.backoff * @backoff_factor
        Logger.info "Caveatica.Connection.connect backoff: #{inspect(backoff, [pretty: true, width: 0])}"
        if backoff < @max_backoff do
          Logger.error "Caveatica.Connection: Retrying in #{backoff}ms..."
          Process.send_after(self(), :connect, trunc(backoff))
          %{state | attempts: attempts + 1, backoff: backoff}
        else
          Logger.error "Caveatica.Connection: Too many failed attempts, rebooting"
          Nerves.Runtime.reboot()
          %{state | status: :dead}
        end
      response ->
        Logger.info "Caveatica.Connection.connect received unexpected response: #{inspect(response)}"
        Process.send_after(self(), :connect, state.backoff)
        state
    end
  end

  def ssh_disconnected(term) do
    Logger.info("Caveatica.Connection: Received SSH disconnect: #{term}")
    {:ok} = GenServer.call(@name, :reset)
    GenServer.cast(@name, :connect)
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
