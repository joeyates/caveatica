defmodule Caveatica.SocketClient do
  @moduledoc """
  Connect to caveatica_controller's 'control' socket
  """

  use Slipstream, restart: :permanent

  require Logger

  @topic "control"
  # ms
  @request_interval 10_000

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
    timer = :timer.send_interval(@request_interval, self(), :request_metrics)

    {
      :ok,
      socket
      |> assign(:ping_timer, timer)
      |> join(@topic)
    }
  end

  @impl Slipstream
  def handle_disconnect(reason, socket) do
    Logger.info("__MODULE__.handle_disconnect: #{inspect(reason)}")

    ping_timer = socket.assigns[:ping_timer]

    if ping_timer do
      :timer.cancel(ping_timer)
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
  def handle_info(:request_metrics, socket) do
    Logger.debug("Requesting metrics")
    {:ok, ref} = push(socket, @topic, "get_metrics", %{format: "json"})

    {:noreply, assign(socket, :metrics_request, ref)}
  end

  @impl Slipstream
  def handle_reply(ref, metrics, socket) do
    if ref == socket.assigns.metrics_request do
      Logger.debug("Got metrics #{inspect(metrics)}")
    end

    {:ok, socket}
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
    Caveatica.light_on()

    {:ok, socket}
  end

  def handle_message(@topic, "light", %{"state" => "off"}, socket) do
    Logger.debug("light off")
    Caveatica.light_off()

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
