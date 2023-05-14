defmodule Caveatica.Camera do
  use GenServer
  require Logger

  @name :camera
  @photo_interval 5000 # ms
  @upload_path to_charlist("/home/dokku/caveatica/data/caveatica.jpg")
  @lock_path to_charlist("/home/dokku/caveatica/data/caveatica.lock")

  def start_link(_opts) do
    Logger.info "Caveatica.Camera.start_link/1"
    GenServer.start_link(__MODULE__, %{}, name: @name)
  end

  @impl true
  def init(_opts) do
    Logger.info "Caveatica.Camera.init/1"

    # Give Connection time to start
    Process.send_after(self(), :take_photo, @photo_interval)

    {:ok, nil}
  end

  @impl true
  def handle_info(:take_photo, state) do
    Logger.info "Caveatica.Camera.handle_info `:take_photo`"
    pid = Process.whereis(:connection)
    {:message_queue_len, length} = Process.info(pid, :message_queue_len)
    Logger.info "Caveatica.Camera.handle_info, Connection message queue length: #{length}"
    if length == 0 do
      lock_exists = lock_exists()
      Logger.info("Caveatica.Camera.handle_info, lock_exists: #{lock_exists}")
      if !lock_exists do
        take_photo()
        create_lock()
      end
    end

    Process.send_after(self(), :take_photo, @photo_interval)

    {:noreply, state}
  end

  defp create_lock do
    result = GenServer.call(:connection, {:send_binary, %{binary: "lock", pathname: @lock_path}}, :infinity)
    Logger.info "Caveatica.Camera.create_lock/0 send_binary result: #{inspect(result, [pretty: true, width: 0])}"
  end

  defp lock_exists do
    case GenServer.call(:connection, {:file_info, @lock_path}, :infinity) do
      {:ok, info} ->
        Logger.info("Caveatica.Camera.lock_exists info: #{inspect(info, [pretty: true, width: 0])}")
        true
      _ ->
        Logger.info("Caveatica.Camera.lock_exists doesn't exist")
        false
    end
  end

  defp take_photo do
    result = GenServer.call(:connection, {:send_binary, %{binary: Picam.next_frame(), pathname: @upload_path}}, :infinity)
    Logger.info "Caveatica.Camera.take_photo/0 send_binary result: #{inspect(result, [pretty: true, width: 0])}"
  end
end
