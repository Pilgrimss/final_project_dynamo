defmodule Dynamo.Client do
  import Emulation, only: [send: 2, timer: 1, timer: 2, cancel_timer: 1, now: 0, whoami: 0]
  import Kernel,
         except: [spawn: 3, spawn: 1, spawn_link: 1, spawn_link: 3, send: 2]

  @moduledoc """
  A client that can be used to connect and send
  requests to Dynamo.
  """
  alias __MODULE__
  defstruct(
    seeds: nil,
    workers: nil, # minimum number of nodes
    readers: nil, # responses to finish a get request
    writers: nil, # minimum number of responses to succeed a put request
    request_timeout: nil,
    request_timer: nil
  )

  @doc """
  Construct a new Dynamo Client.
  """
  @spec new_client(
          [atom()],
          non_neg_integer(),
          non_neg_integer(),
          non_neg_integer(),
          non_neg_integer()
         ) :: %Client{}
  def new_client(
        seeds,
        workers,
        readers,
        writers,
        request_timeout) do
    %Client{
      seeds: seeds,
      workers: workers,
      readers: readers,
      writers: writers,
      request_timeout: request_timeout
    }
  end

  @spec reset_request_timer(%Client{}) :: %Client{}
  defp reset_request_timer(client) do
    case client.request_timer do
      nil -> %{client|request_timer: timer(client.request_timeout)}
      _ -> cancel_timer(client.request_timer)
           %{client|request_timer: timer(client.request_timeout)}
    end
  end

  @spec download(%Client{}) :: [atom()]
  defp download(client) do
    seed = Enum.random(client.seeds)
    send(seed, :download)
    receive do
      {_, membership} -> membership
    end
  end

  @spec preference_list([atom()], any()) :: [atom()]
  defp preference_list(membership, key) do
    hash_key = Dynamo.Hash.hash(key)
  end
  @doc """
  Send a get request to Dynamo
  """
  @spec get(%Client{}, any()) :: {:empty | any(), %Client{}}
  def get(client, key) do
    # pick a random node from seeds

    receive do
      {_, object} ->
        {object, client}
    end
  end


  @doc """
  Send an put request to the RSM.
  """
  @spec put(%Client{}, any(), any()) :: {:ok, %Client{}}
  def put(client, key, object) do
    router = client.router
    send(router, {:put, key, object})

    receive do
      {_, :ok} ->
        {:ok, client}
    end
  end
end

