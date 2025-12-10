defmodule Caveatica.Camera do
  use GenServer
  require Logger

  @name :camera
  # ms
  @photo_interval 1000

  def start_link(_opts) do
    Logger.info("Caveatica.Camera.start_link/1")
    GenServer.start_link(__MODULE__, %{}, name: @name)
  end

  @impl true
  def init(_opts) do
    Logger.info("Caveatica.Camera.init/1")

    Process.send_after(self(), :upload_photo, @photo_interval)

    {:ok, nil}
  end

  @impl true
  def handle_info(:upload_photo, state) do
    upload_photo()

    Process.send_after(self(), :upload_photo, @photo_interval)

    {:noreply, state}
  end

  defp upload_photo do
    binary = Picam.next_frame()
    Caveatica.SocketClient.upload_image(binary)
  end
end
