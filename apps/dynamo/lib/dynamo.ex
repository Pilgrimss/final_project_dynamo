defmodule Dynamo do
  @moduledoc """
  An implementation of the Dynamo key-value store.
  """

  import Emulation, only: [send: 2, timer: 1, timer: 2, cancel_timer: 1, now: 0, whoami: 0]

  import Kernel,
         except: [spawn: 3, spawn: 1, spawn_link: 1, spawn_link: 3, send: 2]

  require Fuzzers
  # This allows you to use Elixir's loggers
  # for messages. See
  # https://timber.io/blog/the-ultimate-guide-to-logging-in-elixir/
  # if you are interested in this. Note we currently purge all logs
  # below Info
  require Logger

  defstruct(
    view: nil, # the membership view mapping: node -> the set of tokens
    seeds: nil,
    merkle_trees: nil,
    store: nil
  )

  @spec new_configuration(
    %{},
    [atom()],
    non_neg_integer(),
    non_neg_integer(),
    non_neg_integer()
    ) :: %Dynamo{}
  def new_configuration(
    view,
    seeds,
    request_timeout,
    min_reads,
    min_writes
    ) do
    %Dynamo{
    view: view,
    seeds: seeds,
    merkle_trees: nil,
    store: %{}
    }
  end

  @spec put(%Dynamo{}, any(), any()) :: %Dynamo{}
  defp put(state, key, object) do
    %{state | store: put(state.store, key, object)}
  end

  @spec get(%Dynamo{}, any()) :: {:ok, any()} | :error
  defp get(state, key) do
    Map.fetch(state.store, key)
  end

end