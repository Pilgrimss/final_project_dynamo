defmodule KVS do
  @moduledoc """
  Documentation for `KVS`.
  """
  @server Application.fetch_env!(:kvs, :server)
  @nodes Application.fetch_env!(:kvs, :nodes)

  def start() do
    :pg2.create(@server)
    :lists.foreach(fn _ -> :pg2.join(@server, spawn(@server, :store, [KVS.Node.new()])) end, :lists.seq(0, @nodes))
  end

  def stop() do
    :lists.foreach(fn pid -> :pg2.leave(@server, pid) end, :pg2.get_members(@server))
  end

  @spec store(%KVS.Node{}) :: no_return()
  def store(node) do
    receive do
      {sender, {:get, key}} ->
        ring = KVS.HashRing.new(:pg2.get_members(@server))
        preference_list = KVS.HashRing.lookup(ring, key)
        :lists.foreach(fn pid -> send(pid, {self(), {:retrieve, sender, key}}) end, preference_list)
        store(KVS.Node.add_read(node, {sender, key}))

      {sender, {:retrieve, client, key}} ->
        send(sender, {self(), {:retrieved, client, key, KVS.Node.get(node, key)}})
        store(node)

      {sender, {:retrieved, client, key, object}} ->
        case KVS.Node.drop_read(node, {client, key}, object) do
          {:ok, objects, node} -> send(client, objects)
            store(node)
          node -> store(node)
        end

      {sender, {:put, key, object}} ->
        ring = KVS.HashRing.new(:pg2.get_members(@server))
        preference_list = KVS.HashRing.lookup(ring, key)
        :lists.foreach(fn pid -> send(pid, {self(), {:update, sender, key, object}}) end, preference_list)
        store(KVS.Node.add_write(node, {sender, key}))

      {sender, {:update, client, key, object}} ->
        send(sender, {self(), {:updated, client, key}})
        store(KVS.Node.put(node, key, object))

      {sender, {:updated, client, key}} ->
        case KVS.Node.drop_write(node, {client, key}) do
          {:ok, node} ->
            send(client, {self(), :ok})
            store(node)
          node ->
            store(node)
        end


      {sender, {:tree_check_request, tree_range}} ->
        send(sender, {:tree_check_response, node.merkel_tree_map[tree_range], tree_range})
        store(node)

      # to do,  we need timer to send , similar to heart beat
      # to do, we need to calc who shall we send
      {sender, {:tree_check_response, other_tree, tree_range}} ->

        {_, list} = KVS.Node.compare_merkle_tree(node.merkle_tree_map[tree_range].root, other_tree.root,[])
        node = KVS.Node.insert_keys(node,list, tree_range)
        store(node)


      # debug functions
      {sender, :download} ->
        send(sender, {self(), node.data})
        store(node)

      # debug reconcile
      {sender, {:insert_keys_intree, list,tree_range}} ->
        node = KVS.Node.insert_keys(node, list, tree_range)
        send(sender, {self(), node})
        store(node)

      {sender, {:download_tree,tree_range}} ->
        send(sender, {self(), node.merkle_tree_map[tree_range]})
        store(node)


    end
  end
end
