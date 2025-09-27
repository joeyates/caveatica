defmodule Caveatica.Light do
  @moduledoc false

  require Logger

  @light_label "GPIO23"

  def turn_on() do
    {:ok, gpio} = Circuits.GPIO.open(@light_label, :output)
    Circuits.GPIO.write(@light_label, 1)
    Circuits.GPIO.close(gpio)
  end

  def turn_off() do
    {:ok, gpio} = Circuits.GPIO.open(@light_label, :output)
    Circuits.GPIO.write(gpio, 0)
    Circuits.GPIO.close(gpio)
  end

  def status() do
    {:ok, gpio} = Circuits.GPIO.open(@light_label, :input)
    value = Circuits.GPIO.read(gpio)
    Logger.info("light pin value: #{inspect(value)}")
    Circuits.GPIO.close(gpio)

    "foo"
  end
end
