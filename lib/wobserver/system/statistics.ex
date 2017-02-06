defmodule Wobserver.System.Statistics do
  @moduledoc ~S"""
  Handles system statistics.
  """

  @typedoc ~S"""
  System statistics.
  """
  @type t :: %__MODULE__{
    uptime: integer,
    process_running: integer,
    process_total: integer,
    process_max: integer,
    input: integer,
    output: integer,
  }

  defstruct [
    uptime: 0,
    process_running: 0,
    process_total: 0,
    process_max: 0,
    input: 0,
    output: 0,
  ]

  @doc ~S"""
  Returns system statistics.
  """
  @spec overview :: Wobserver.System.Statistics.t
  def overview do
    {input, output} = io()
    {running, total, max} = process()

    %__MODULE__{
      uptime: uptime(),
      process_running: running,
      process_total: total,
      process_max: max,
      input: input,
      output: output,
    }
  end

  defp uptime do
    {time, _?} = :erlang.statistics(:wall_clock)

    time
  end

  defp io do
    {
      {:input, input},
      {:output, output}
    } = :erlang.statistics(:io)

    {input, output}
  end

  defp process do
    {
      :erlang.statistics(:run_queue),
      :erlang.system_info(:process_count),
      :erlang.system_info(:process_limit),
    }
  end
end
