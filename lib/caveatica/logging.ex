defmodule Caveatica.Logging do
  defstruct ~w(index message time level file line function mfa)a

  def messages(start \\ 0) do
    start
    |> RingLogger.get()
    |> Enum.map(fn {_level, {Logger, message, time, info}} -> {message, time, info} end)
    |> Enum.filter(& elem(&1, 2)[:application] == :caveatica)
    |> Enum.map(fn {message, time, info} ->
      %__MODULE__{
        index: info[:index],
        message: message,
        time: time,
        level: info[:erl_level],
        file: info[:file],
        line: info[:line],
        function: info[:function],
        mfa: info[:mfa]
      }
    end)
  end

  def to_string(%__MODULE__{} = m, short: true) do
    "[#{m.index}] #{m.message}"
  end

  def to_string(%__MODULE__{} = m) do
    "[#{m.index}] #{m.file}:#{m.line} - #{m.function} - #{m.message}"
  end
end
