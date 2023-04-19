defmodule Caveatica.Camera do
  use GenServer
  require Logger

  @photo_interval 5000 # ms
  @upload_path '/home/dokku/caveatica/data/caveatica.jpg'

  def start_link(_opts) do
    Logger.info "Caveatica.Camera.start_link/1"
    GenServer.start_link(__MODULE__, %{})
  end

  @impl true
  def init(_opts) do
    Logger.info "Caveatica.Camera.init/1"

    send(self(), :take_photo)

    {:ok, nil}
  end

  @impl true
  def handle_info(:take_photo, state) do
    Logger.info "Caveatica.Camera.handle_info `:take_photo`"
    take_photo()
    Process.send_after(self(), :take_photo, @photo_interval)

    {:noreply, state}
  end

  defp take_photo do
    result = GenServer.call(:connection, {:send_binary, %{binary: Picam.next_frame(), pathname: @upload_path}}, :infinity)
    Logger.info "Caveatica.Camera.take_photo/0 send_binary result: #{inspect(result, [pretty: true, width: 0])}"
  end
end
