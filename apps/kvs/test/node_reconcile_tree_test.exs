defmodule NodeReconcileTest do
  use ExUnit.Case
  doctest KVS

  test "node insert keys" do
    KVS.start()
    [node0, node1 | tail] = KVS.Client.get_servers()

    send(node0, {self(), {:insert_keys_intree, ["ada","java"], "first"}})
    receive do
      {sender, node} ->
        IO.inspect(node.merkle_tree_map)
    end
  end

  test "node reconcile keys" do
    KVS.start()
    list1 = [{"ada",1},{"java",1}]
    list2 = [{"python",1},{"elixir",1}]
    list3 = [{"ada",1},{"java",1},{"python",1},{"elixir",1}]
    m1 = Merkel.new(list1)
    m2 = Merkel.new(list2)
    m3 = Merkel.new(list3)
    [node0, node1 | tail] = KVS.Client.get_servers()

    send(node0, {self(), {:insert_keys_intree, ["ada","java"], "first"}})
    receive do
      {sender, node} ->
        Map.get(node.merkle_tree_map,"first").root.key_hash == m1.root.key_hash
    end
    send(node0, {self(), {:tree_check_response, m2, "first"}})
    send(node0, {self(), {:download_tree, "first"}})

    receive do
      {sender, tree} ->
        tree.root.key_hash == m3.root.key_hash
    end
  end



end
