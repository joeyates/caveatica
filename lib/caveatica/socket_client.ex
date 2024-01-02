defmodule Caveatica.SocketClient do
  @moduledoc """
  Connect to caveatica_controller's 'control' socket
  """

  use Slipstream, restart: :permanent

  require Logger

  @topic "control"

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
    {
      :ok,
      socket
      |> join(@topic)
    }
  end

  @impl Slipstream
  def handle_continue(:start_ping, socket) do
    Logger.info("handle_continue")
    timer = :timer.send_interval(1000, self(), :request_metrics)

    {:noreply, assign(socket, :ping_timer, timer)}
  end

  @impl Slipstream
  def handle_connect(socket) do
    Logger.info("handle_connect")
    {:ok, join(socket, @topic)}
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

    {:ok, socket}
  end

  def handle_message(@topic, "nudge_closed", _message, socket) do
    Logger.info("nudge_closed")

    {:ok, socket}
  end

  def handle_message(@topic, "nudge_open", _message, socket) do
    Logger.info("nudge_open")

    {:ok, socket}
  end

  def handle_message(@topic, "open", _message, socket) do
    Logger.info("open")

    {:ok, socket}
  end

  def handle_message(@topic, event, message, socket) do
    Logger.error("Unexpected push from server: #{event} #{inspect(message)}")

    {:ok, socket}
  end

  @impl Slipstream
  def handle_disconnect(_reason, socket) do
    ping_timer = socket.assigns[:ping_timer]

    if ping_timer do
      :timer.cancel(ping_timer)
    end

    {:stop, :normal, socket}
  end
end
