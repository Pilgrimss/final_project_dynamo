defmodule KVS.HashRing do

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
  )

  @hash_space :math.pow(2, 32)-1
  @partitions Application.get_env(:kvs, :partitions)
  @workers Application.get_env(:kvs, :workers)

  @doc """
  Create a new hash ring with no nodes added yet
  """
  def new(nodes) do
    %HashRing{ ring:
    nodes
    |> Enum.map(fn x -> node_to_positions(x) end)
    |> :lists.flatten()
    |> Enum.reduce(:gb_trees.empty(), fn {pos, node}, tree -> :gb_trees.insert(pos, node, tree) end)
    }
  end

  def lookup(ring, key) do
    case :gb_trees.is_empty(ring.ring) do
      true -> {:error, :empty_ring}
      false ->
        hkey = hash(key)
        pos = :gb_trees.iterator_from(hkey, ring.ring)
        MapSet.to_list(preference_list(pos, MapSet.new()))
    end
  end

  def preference_list(pos, list) do
    case MapSet.size(list) do
      @workers -> list
      _ ->
        case :gb_trees.next(pos) do
          {_, node, iter} -> preference_list(iter, MapSet.put(list, node))
          none -> list
        end
    end
  end

  def remove(ring, node) do
    positions = node_to_positions(node)
    %{ring|ring: List.foldl(positions, ring.ring, fn {pos, _}, tree -> :gb_trees.delete_any(pos, tree) end)}
  end

  def build_ring(nodes, ring) do
    List.foldl(nodes, ring, fn {pos, node}, tree -> :gb_trees.insert(pos, node, tree) end)
  end

  def node_to_positions(node) do
    :lists.seq(0, @partitions-1)
    |> Enum.map(fn x -> {hash(node, x), node} end)
  end

  defp hash(key) do
    Base.encode16(:crypto.hash(:md5, :erlang.term_to_binary(key)))
  end

  defp hash(x, y) do
     Base.encode16(:crypto.hash(:md5, <<:erlang.term_to_binary(x)::binary, :erlang.term_to_binary(y)::binary>>))
  end
end