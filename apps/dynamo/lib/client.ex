defmodule Dynamo.Client do
  import Emulation, only: [send: 2]
  import Router
  import Kernel,
         except: [spawn: 3, spawn: 1, spawn_link: 1, spawn_link: 3, send: 2]

  @moduledoc """
  A client that can be used to connect and send
  requests to Dynamo.
  """
  alias __MODULE__
  @enforce_keys [:router]
  defstruct(router: nil)

  @doc """
  Construct a new Raft Client. This takes an ID of
  any process that is in the RSM. We rely on
  redirect messages to find the correct leader.
  """
  @spec new_client() :: %Client{router: atom()}
  def new_client(member) do
    %Client{router: member}
  end

  @doc """
  Send a dequeue request to Dynamo
  """
  @spec get(%Client{}, any()) :: {:empty | any(), %Client{}}
  def get(client, key) do
    router = client.router
    send(router, {:get, key})

    receive do
      {_, object} ->
        {object, client}
    end
  end

  @doc """
  Send an enqueue request to the RSM.
  """
  @spec put(%Client{}, any()) :: {:ok, %Client{}}
  def put(client, key, object) do
    router = client.router
    send(router, {:put, key, object})

    receive do
      {_, :ok} ->
        {:ok, client}
    end
  end
end

