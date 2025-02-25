defmodule Caveatica.Light do
  require Logger

  # GPIO23 == pin 16
  @pin 23

  def on do
    {:ok, gpio} = Circuits.GPIO.open(@pin, :output)
    Circuits.GPIO.write(gpio, 1)
    Circuits.GPIO.close(gpio)
  end

  def off do
    {:ok, gpio} = Circuits.GPIO.open(@pin, :output)
    Circuits.GPIO.write(gpio, 0)
    Circuits.GPIO.close(gpio)
  end
end
