defmodule Dynamo.HashRing do

  @moduledoc """
  An implementation for the consistent hashing.
  - The ring is a fixed circular space of 2^32 points.
  - The ring is divided into Q equally-sized partitions with Q>> S.
  and each node is assigned Q/S tokens (partitions).
  where S is the number of nodes in this system.
  - When a node leaves the system, its token are randomly distributed to the remaining nodes.
  - When a node joins the system, it "steals" tokens from nodes in the system.
  - Keys are applied a MD5 hash to generate a 128-bit identifier to yield its position on the tree,
  and then walking the ring clockwise to find the first N successor physical nodes in the ring to form it preference list


  """
  alias __MODULE__

  defstruct(
    ring: nil,
    nodes: nil
  )

  @hash_space :math.pow(2, 32)-1
  @partitions Application.get_env(:ring, :partitions)
  @workers Application.get_env(:cluster, :workers)
  @doc """
  Create a new hash ring with no nodes added yet
  """
  @spec new() :: %HashRing{}
  defp new() do
    %HashRing{}
  end

  @doc """
  Create a new hash ring with the seed node
  """
  @spec new(node()) :: %HashRing{}
  def new(node) do
    %HashRing{
    ring: List.duplicate(node, @partitions),
    nodes: [node]
    }
  end

  @doc """
  Add a new node to the ring
  """

  def add_node(ring, node) do
    if node in ring.nodes do
      :error
    else
      ring = %{ring| nodes: [node|ring.nodes]}
      tokens = trunc(@partitions/length(ring.nodes))
      steal = Enum.take_random(getIndexes(), tokens)
      %{ring| ring: Enum.reduce(steal, ring.ring, &List.replace_at(&2, &1, node))}
    end
  end

  def del_node(ring, node) do
    if node in ring.nodes do
      ring = %{ring| nodes: ring.nodes -- [node]}
      ring = %{ring| ring: Enum.map(ring.ring, fn x ->
        if x==node do Enum.random(ring.nodes) else x end end)}
    else
      :error
    end
  end

  def key_to_nodes(ring, key) do
    get_nodes(ring, getPosition(Dynamo.Hash.hash(key)+1), MapSet.new())
  end

  def getPosition(num) do
    rem(num, @partitions)
  end

  def getIndexes() do
    Enum.to_list(1..@partitions)
  end

  defp get_nodes(ring, position, set) do
    set = MapSet.put(set, Enum.at(ring.ring, position))
    if MapSet.size(set) == @workers do
      set
    else
      get_nodes(ring, getPosition(position+1), set)
    end
  end


end