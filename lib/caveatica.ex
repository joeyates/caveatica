defmodule Caveatica do
  @moduledoc """
  Documentation for `Caveatica`.
  """
  @open_pin 17 # GPIO17 == pin 11
  @close_pin 18 # GPIO18 == pin 12
  @duration 3000 # milliseconds

  def open(duration \\ @duration) do
    start_raising()
    :timer.sleep(duration)
    stop_raising()
  end

  def close(duration \\ @duration) do
    start_lowering()
    :timer.sleep(duration)
    stop_lowering()
  end

  defp start_raising do
    {:ok, gpio} = Circuits.GPIO.open(@open_pin, :output)
    Circuits.GPIO.write(gpio, 1)
    Circuits.GPIO.close(gpio)
  end

  defp stop_raising do
    {:ok, gpio} = Circuits.GPIO.open(@open_pin, :output)
    Circuits.GPIO.write(gpio, 0)
    Circuits.GPIO.close(gpio)
  end

  defp start_lowering do
    {:ok, gpio} = Circuits.GPIO.open(@close_pin, :output)
    Circuits.GPIO.write(gpio, 1)
    Circuits.GPIO.close(gpio)
  end

  defp stop_lowering do
    {:ok, gpio} = Circuits.GPIO.open(@close_pin, :output)
    Circuits.GPIO.write(gpio, 0)
    Circuits.GPIO.close(gpio)
  end
end
