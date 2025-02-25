defmodule Caveatica do
  @moduledoc """
  Documentation for `Caveatica`.
  """
  # GPIO17 == pin 11
  @open_pin 17
  # GPIO18 == pin 12
  @close_pin 18
  # GPIO23 == pin 16
  @light_pin 23

  def open(duration \\ @open_duration) do
    start_raising()
    :timer.sleep(duration)
    stop_raising()
  end

  def close(duration \\ @close_duration) do
    start_lowering()
    :timer.sleep(duration)
    stop_lowering()
  end

  def light_on do
    {:ok, gpio} = Circuits.GPIO.open(@light_pin, :output)
    Circuits.GPIO.write(gpio, 1)
    Circuits.GPIO.close(gpio)
  end

  def light_off do
    {:ok, gpio} = Circuits.GPIO.open(@light_pin, :output)
    Circuits.GPIO.write(gpio, 0)
    Circuits.GPIO.close(gpio)
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
