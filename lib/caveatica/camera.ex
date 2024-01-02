defmodule Caveatica.Camera do
  use GenServer
  require Logger

  @name :camera
  @photo_interval 1000 # ms
  @upload_path to_charlist("/home/dokku/caveatica/data/caveatica.jpg")
  @photo_ready_lock_path to_charlist("/home/dokku/caveatica/data/caveatica.lock")

  def start_link(_opts) do
    Logger.info "Caveatica.Camera.start_link/1"
    GenServer.start_link(__MODULE__, %{}, name: @name)
  end

  @impl true
  def init(_opts) do
    Logger.info "Caveatica.Camera.init/1"

    # Give Connection time to start
    Process.send_after(self(), :upload_photo, @photo_interval)

    {:ok, nil}
  end

  @impl true
  def handle_info(:upload_photo, state) do
    Logger.info "Caveatica.Camera checking whether to upload photo"
    pid = Process.whereis(:connection)
    with {:message_queue_len, 0} <- Process.info(pid, :message_queue_len),
         %{status: :connected} <- Caveatica.Connection.status(),
         false <- lock_exists() do
      upload_photo()
      create_lock()
    else
      _ ->
        Logger.info "Caveatica.Camera skipping photo upload"
    end

    Process.send_after(self(), :upload_photo, @photo_interval)

    {:noreply, state}
  end

  defp create_lock do
    result = GenServer.call(:connection, {:send_binary, %{binary: "lock", pathname: @photo_ready_lock_path}}, :infinity)
    Logger.info "Caveatica.Camera.create_lock/0 result: #{inspect(result, [pretty: true, width: 0])}"
  end

  defp lock_exists do
    case GenServer.call(:connection, {:file_info, @photo_ready_lock_path}, :infinity) do
      {:ok, _info} ->
        Logger.info("Caveatica.Camera photo ready lock exists on server")
        true
      _ ->
        Logger.info("Caveatica.Camera photo ready lock doesn't exist on server")
        false
    end
  end

  defp upload_photo do
    Logger.info "Caveatica.Camera uploading photo`"
    result = GenServer.call(:connection, {:send_binary, %{binary: Picam.next_frame(), pathname: @upload_path}}, :infinity)
    Logger.info "Caveatica.Camera.upload_photo/0 result: #{inspect(result, [pretty: true, width: 0])}"
  end
end
