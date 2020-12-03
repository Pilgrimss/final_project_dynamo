defmodule KVS.Node do

  @workers Application.fetch_env!(:kvs, :workers)
  @writers Application.fetch_env!(:kvs, :writers)
  @readers Application.fetch_env!(:kvs, :readers)

  defstruct(
    data: nil,
    pending_r: nil,
    pending_w: nil
  )

  @spec new() :: %KVS.Node{}
  def new() do
    %KVS.Node{
    data: %{},
    pending_r: %{},
    pending_w: %{}
    }
  end

  @spec get(%KVS.Node{}, any()) :: any()
  def get(node, key) do
    Map.get(node.data, key, :error)
  end

  @spec put(%KVS.Node{}, any(), any()):: %KVS.Node{}
  def put(node, key, object) do
    %{node|data: Map.put(node.data, key, object)}
  end

  def add_write(node, request) do
    %{node|pending_w: Map.put(node.pending_w,request, @writers)}
  end

  def drop_write(node, request) do
    case Map.get(node.pending_w, request, :error) do
      :error -> node
      1 -> {:ok, %{node| pending_w: Map.delete(node.pending_w, request)}}
      count -> %{node| pending_w: Map.put(node.pending_w, request, count-1)}
    end
  end

  def add_read(node, request) do
    %{node|pending_r: Map.put(node.pending_r, request, {@readers, []})}
  end

  def drop_read(node, request, object) do
    case Map.get(node.pending_r, request, :error) do
      :error -> node
      {1, objects} ->
        node = %{node| pending_r: Map.delete(node.pending_r,request)}
        {:ok, [object|objects], node}
      {count, objects} ->
        %{node| pending_r: Map.put(node.pending_r, request, {count-1, [object|objects]})}
    end
  end

end
