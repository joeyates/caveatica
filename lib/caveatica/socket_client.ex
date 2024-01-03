defmodule Caveatica.SocketClient do
  @moduledoc """
  Connect to caveatica_controller's 'control' socket
  """

  use Slipstream, restart: :permanent

  require Logger

  @topic "control"
  @request_interval 10_000 # ms

  def start_link(args) do
    Slipstream.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl Slipstream
  def init(config) do
    Logger.info("config: #{inspect(config)}")
    result = connect(config)
    Logger.info("Socket connect/1 result: #{inspect(result)}")
    {:ok, socket} = result
    {:ok, socket}
  end

  @impl Slipstream
  def handle_connect(socket) do
    Logger.info("handle_connect")
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
    Logger.info("handle_disconnect: #{inspect(reason)}")

    ping_timer = socket.assigns[:ping_timer]

    if ping_timer do
      :timer.cancel(ping_timer)
    end

    case reconnect(socket) do
      {:ok, socket} -> {:ok, socket}
      {:error, reason} ->
        Logger.info("reconnect failed: #{inspect(reason)}")
        {:stop, reason, socket}
    end
  end

  @impl Slipstream
  def handle_topic_close(topic, reason, socket) do
    Logger.info("handle_topic_close: #{inspect(reason)}")
    rejoin(socket, topic)
  end

  @impl Slipstream
  def handle_info(:request_metrics, socket) do
    Logger.info("Requesting metrics")
    {:ok, ref} = push(socket, @topic, "get_metrics", %{format: "json"})

    {:noreply, assign(socket, :metrics_request, ref)}
  end

  @impl Slipstream
  def handle_reply(ref, metrics, socket) do
    if ref == socket.assigns.metrics_request do
      Logger.info("Got metrics #{inspect(metrics)}")
    end

    {:ok, socket}
  end

  @impl Slipstream
  def handle_message(@topic, "close", _message, socket) do
    Logger.info("close")
    Caveatica.close()

    {:ok, socket}
  end

  def handle_message(@topic, "nudge_closed", _message, socket) do
    Logger.info("nudge_closed")
    Caveatica.close(100)

    {:ok, socket}
  end

  def handle_message(@topic, "nudge_open", _message, socket) do
    Logger.info("nudge_open")
    Caveatica.open(100)

    {:ok, socket}
  end

  def handle_message(@topic, "open", _message, socket) do
    Logger.info("open")
    Caveatica.open()

    {:ok, socket}
  end

  def handle_message(@topic, event, message, socket) do
    Logger.error("Unexpected push from server: #{event} #{inspect(message)}")

    {:ok, socket}
  end

  @impl Slipstream
  def handle_cast({:upload_image, binary}, socket) do
    Logger.info("handle_cast upload_image, size: #{byte_size(binary)}")
    encoded = Base.encode64(binary)
    push(socket, @topic, "upload_image", %{binary: encoded})
    {:noreply, socket}
  end

  def upload_image(binary) do
    Logger.info("upload_image/1 size: #{byte_size(binary)}")
    :ok = GenServer.cast(__MODULE__, {:upload_image, binary})
  end
end
