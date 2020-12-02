defmodule KVS.Node do
  defstruct(
    data: nil,
    pending_reads: nil,
    pending_writes: nil
  )

  @spec new() :: %KVS.Node{}
  def new() do
    %KVS.Node{
    data: %{},
    pending_reads: [],
    pending_writes: []
    }
  end

  @spec get(%KVS.Node{}, any()) :: any()
  def get(node, key) do
    Map.fetch(node.data, key)
  end

  @spec put(%KVS.Node{}, any(), any()):: %KVS.Node{}
  def put(node, key, object) do
    %{node|data: Map.put(node.data, key, object)}
  end

end
