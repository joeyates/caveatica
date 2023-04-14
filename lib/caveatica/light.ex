defmodule Caveatica.Light do
  require Logger

  @pin 23 # GPIO23 == pin 16

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
