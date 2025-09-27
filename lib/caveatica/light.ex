defmodule Caveatica.Light do
  @moduledoc false

  require Logger

  # GPIO23 == pin 16
  @light_pin 23

  def turn_on() do
    {:ok, gpio} = Circuits.GPIO.open(@light_pin, :output)
    Circuits.GPIO.write(gpio, 1)
    Circuits.GPIO.close(gpio)
  end

  def turn_off() do
    {:ok, gpio} = Circuits.GPIO.open(@light_pin, :output)
    Circuits.GPIO.write(gpio, 0)
    Circuits.GPIO.close(gpio)
  end

  def status() do
    {:ok, gpio} = Circuits.GPIO.open(@light_pin, :input)
    value = Circuits.GPIO.read(gpio)
    Logger.info("light pin value: #{inspect(value)}")
    Circuits.GPIO.close(gpio)

    "foo"
  end
end
