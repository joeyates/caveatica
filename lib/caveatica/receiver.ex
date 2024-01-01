defmodule Caveatica.Receiver do
  use GenServer
  require Logger

  @database_url Application.compile_env!(:caveatica, :database_url)

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts)
  end

  @impl true
  def init(_opts \\ []) do
    Logger.info("Caveatica.Receiver.init/1")
    config = Ecto.Repo.Supervisor.parse_url(@database_url)
    {:ok, pid} = Postgrex.Notifications.start_link(config)
    {:ok, ref} = Postgrex.Notifications.listen(pid, "caveatica_notification")
    {:ok, %{pid: pid, ref: ref}}
  end

  @impl true
  def handle_info({:notification, _pid, _ref, _channel_name, payload}, _state) do
    Logger.info("Receiver received payload: #{inspect(payload)}")
    {:noreply, :event_handled}
  end

  def handle_info(_value, _state) do
    {:noreply, :event_received}
  end
end
