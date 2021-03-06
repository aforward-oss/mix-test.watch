defmodule MixTestWatch.PortRunner do
  @moduledoc """
  Run the tasks in a new OS process via ports
  """

  alias MixTestWatch.Config

  @doc """
  Run tests using the runner from the config.
  """
  def run(%Config{} = config) do
    command = build_tasks_cmds(config)
    System.cmd("sh", ["-c", command], into: IO.stream(:stdio, :line))
    :ok
  end


  @doc """
  Build a shell command that runs the desired mix task(s).

  Colour is forced on- normally Elixir would not print ANSI colours while
  running inside a port.
  """
  def build_tasks_cmds(config = %Config{}) do
    config.tasks
    |> Enum.map(&task_command(&1, config))
    |> Enum.join(" && ")
  end


  defp ansi(%{ansi_enabled: :ignore}) do
    []
  end

  defp ansi(%{ansi_enabled: enabled}) do
    ["do", "run -e 'Application.put_env(:elixir, :ansi_enabled, #{enabled});',"]
  end

  defp task_command(task, config) do
    args = Enum.join(config.cli_args, " ")
    [config.cli_executable] ++ ansi(config) ++ [task, args]
    |> Enum.filter(&(&1))
    |> Enum.join(" ")
    |> fn(command) -> "MIX_ENV=test #{command}" end.()
    |> String.trim()
  end
end
