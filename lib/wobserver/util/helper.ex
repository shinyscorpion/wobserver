defmodule Wobserver.Util.Helper do
  @moduledoc ~S"""
  Helper functions and JSON encoders.
  """

  alias Poison.Encoder
  alias Encoder.BitString

  defimpl Encoder, for: PID do
    @spec encode(pid :: pid, options :: any) :: String.t
    def encode(pid, options) do
      pid
      |> inspect
      |> BitString.encode(options)
    end
  end

  @doc ~S"""
  Converts Strings to module names or atoms.
  """
  @spec string_to_module(module :: String.t) :: atom
  def string_to_module(module) do
    first_letter = String.first(module)

    case String.capitalize(first_letter) do
      ^first_letter ->
        module
        |> String.split(".")
        |> Enum.map(&String.to_atom/1)
        |> Module.concat
      _ ->
        module
        |> String.to_atom
    end
  end

  @doc ~S"""
  Formats function information as readable string.

  Example:
  ```bash
  iex> format_function {Logger, :log, 2}
  "Logger.log/2"
  ```
  ```bash
  iex> format_function :format_function
  "format_function"
  ```
  ```bash
  iex> format_function nil
  nil
  ```
  """
  @spec format_function(nil | {atom, atom, integer} | atom) :: String.t | nil
  def format_function(nil), do: nil
  def format_function({module, name, arity}), do: "#{module}.#{name}/#{arity}"
  def format_function(name), do: "#{name}"
end
