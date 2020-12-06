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

  @hash_space round(:math.pow(2, 32)-1)
  @q Application.get_env(:kvs, :Q)
  @nodes Application.get_env(:kvs, :nodes)
  @n Application.get_env(:kvs, :N)

  @doc """
  Create a new hash ring with configuration
  """
  def new() do
    tokens = :lists.seq(0, @hash_space, div(@hash_space+1, @q))
    ring = :ets.new(:ring, [:named_table, :ordered_set, :protected])
    assign_tokens(tokens, @nodes, Map.new())
  end

  defp assign_tokens(tokens, nodes, map) do
    case tokens do
      [] -> map
      [token|tokens] ->
        case nodes do
          [] ->
            [node|nodes] = @nodes
            :ets.insert(:ring, {token, node})
            assign_tokens(tokens, nodes, Map.update(map, node, [token], fn list -> [token|list] end))
          [node|nodes] ->
            :ets.insert(:ring, {token, node})
            assign_tokens(tokens, nodes, Map.update(map, node, [token], fn list -> [token|list] end))
        end
    end
  end

  def lookup(key) do
    hkey = hash(key)
    list = MapSet.to_list(preference_list(hkey, MapSet.new()))
#    IO.inspect([key, list])
  end

  def preference_list(token, set) do
    case MapSet.size(set) do
      @n -> set
      _ ->
        next_token =
        case :ets.next(:ring, token) do
          :"$end_of_table" -> :ets.first(:ring)
          other -> other
        end
        preference_list(next_token, MapSet.put(set, :ets.lookup_element(:ring, next_token, 2)))
    end
  end

#  def remove(ring, node) do
#    positions = node_to_positions(node)
#    %{ring|ring: List.foldl(positions, ring.ring, fn {pos, _}, tree -> :gb_trees.delete_any(pos, tree) end)}
#  end

  defp hash(key) do
    <<_::binary-size(12), value::unsigned-little-integer-size(32)>> = :crypto.hash(:md5, :erlang.term_to_binary(key))
    value
  end

end