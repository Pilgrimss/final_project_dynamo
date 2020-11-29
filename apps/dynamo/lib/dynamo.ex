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
    merkle_tree: nil,
    request_timeout: nil,
    request_timer: nil,
    min_reads: nil, # minimum number of responses to collect for the
    min_writes: nil,
    store: nil
  )

  @spec new_configuration(
    non_neg_integer(),
    non_neg_integer(),
    non_neg_integer()
    ) :: %Dynamo{}
  def new_configuration(
    request_timeout,
    min_reads,
    min_writes
    ) do
    %Dynamo{
    merkle_tree: Merkle.new(),
    request_timeout: request_timeout,
    min_reads: min_reads,
    min_writes: min_writes,
    store: %{}
    }
  end

  @spec put(%Dynamo{}, any(), any()) :: %Dynamo{}
  defp put(state, key, object) do
    %{state | store: put(state.store, key, object)}
  end

  @spec get(%Dynamo{}, any()) :: {:ok, any()} | :error
  defp get(state, key) do
    fetch(state.store, key)
  end

  @spec broadcast(any()) ::[boolean()]
  defp broadcast() do

  end

  @spec coordinator(%Dynamo{}, any()) :: no_return()
  defp coordinator(state, extra_state) do
    receive do
      {sender, {:get, key}} ->
        %{extra_state| key: get(state, key)}
        broadcast({:get, key})
        coordinator(state, extra_state)
      {sender, {:put, key, object}} ->
        %{extra_state| put(state, key)}
        coordinator(state, extra_state)
    end
  end
end