defmodule Caveatica.Light do
  @moduledoc false

  use GenServer

  import GenServer, only: [call: 2]

  alias Circuits.GPIO

  require Logger

  @light_label "GPIO23"

  def start_link(_opts) do
    Logger.info("Caveatica.Light.start_link/1")
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl true
  def init(_) do
    Logger.info("Light init")
    :ok = GPIO.write_one(@light_label, 0)
    {:ok, %{status: :off}}
  end

  @impl true
  def handle_call(:status, _from, state) do
    {:reply, state.status, state}
  end

  def handle_call(:turn_on, _from, state) do
    :ok = GPIO.write_one(@light_label, 1)
    {:reply, :ok, %{state | status: :on}}
  end

  def handle_call(:turn_off, _from, state) do
    :ok = GPIO.write_one(@light_label, 0)
    {:reply, :ok, %{state | status: :off}}
  end

  def turn_on() do
    call(__MODULE__, :turn_on)
  end

  def turn_off() do
    call(__MODULE__, :turn_off)
  end

  def status() do
    call(__MODULE__, :status)
  end
end
