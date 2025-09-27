defmodule Caveatica.SocketClient do
  @moduledoc """
  Connect to caveatica_controller's 'control' socket
  """

  use Slipstream, restart: :permanent

  require Logger

  @topic "control"
  @status_interval _three_seconds = 3_000

  def start_link(args) do
    Slipstream.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl Slipstream
  def init(config) do
    Logger.info("Initializing socket")
    Logger.debug("config: #{inspect(config)}")
    result = connect(config)
    Logger.debug("Socket connect/1 result: #{inspect(result)}")
    {:ok, socket} = result
    {:ok, socket}
  end

  @impl Slipstream
  def handle_connect(socket) do
    Logger.info("#{__MODULE__}.handle_connect")
    status_timer = :timer.send_interval(@status_interval, self(), :send_status)

    {
      :ok,
      socket
      |> assign(:status_timer, status_timer)
      |> join(@topic)
    }
  end

  @impl Slipstream
  def handle_disconnect(reason, socket) do
    Logger.info("__MODULE__.handle_disconnect: #{inspect(reason)}")

    status_timer = socket.assigns[:status_timer]

    socket =
      if status_timer do
        :timer.cancel(status_timer)
        assign(socket, :status_timer, nil)
      else
        socket
      end

    case reconnect(socket) do
      {:ok, socket} ->
        {:ok, socket}

      {:error, reason} ->
        Logger.debug("reconnect failed: #{inspect(reason)}")
        {:stop, reason, socket}
    end
  end

  @impl Slipstream
  def handle_topic_close(topic, reason, socket) do
    Logger.info("#{__MODULE__}.handle_topic_close: #{inspect(reason)}")
    rejoin(socket, topic)
  end

  @impl Slipstream
  def handle_info(:send_status, socket) do
    Logger.debug("Sending status")
    light_status = Caveatica.Light.status()
    {:ok, _ref} = push(socket, @topic, "status", %{light: light_status})

    {:noreply, socket}
  end

  @impl Slipstream
  def handle_message(@topic, "close", %{"duration" => duration}, socket) do
    Logger.debug("SocketClient.handle_message close: #{duration}")
    Caveatica.close(duration)

    {:ok, socket}
  end

  def handle_message(@topic, "open", %{"duration" => duration}, socket) do
    Logger.debug("SocketClient.handle_message open: #{duration}")
    Caveatica.open(duration)

    {:ok, socket}
  end

  def handle_message(@topic, "light", %{"state" => "on"}, socket) do
    Logger.debug("light on")
    Caveatica.Light.turn_on()

    {:ok, socket}
  end

  def handle_message(@topic, "light", %{"state" => "off"}, socket) do
    Logger.debug("light off")
    Caveatica.Light.turn_off()

    {:ok, socket}
  end

  def handle_message(@topic, event, message, socket) do
    Logger.error("Unexpected push from server: #{event} #{inspect(message)}")

    {:ok, socket}
  end

  @impl Slipstream
  def handle_cast({:upload_image, binary}, socket) do
    Logger.debug("handle_cast upload_image, size: #{byte_size(binary)}")
    encoded = Base.encode64(binary)
    push(socket, @topic, "upload_image", %{binary: encoded})
    {:noreply, socket}
  end

  def upload_image(binary) do
    Logger.debug("upload_image/1 size: #{byte_size(binary)}")
    :ok = GenServer.cast(__MODULE__, {:upload_image, binary})
  end
end
