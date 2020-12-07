defmodule KVS do
  @moduledoc """
  Documentation for `KVS`.
  """
  import Emulation, only: [spawn: 2, send: 2, broadcast: 1, timer: 1, now: 0, whoami: 0]

  import Kernel,
         except: [spawn: 3, spawn: 1, spawn_link: 1, spawn_link: 3, send: 2]

  @server Application.fetch_env!(:kvs, :server)
  @nodes Application.fetch_env!(:kvs, :nodes)


  def start() do
    :ets.new(:nodes, [:named_table, :set, :protected])
    tokens = KVS.HashRing.new()
    :pg2.create(@server)
    :lists.foreach(fn node -> :pg2.join(@server, spawn(node, fn -> KVS.store(KVS.Node.new(tokens[node])) end)) end, @nodes)
    Enum.zip(@nodes, :pg2.get_members(@server))
    |> Enum.map(fn {x,y} -> :ets.insert(:nodes, {x, y}) end)
  end

  def stop() do
    :lists.foreach(fn pid -> :pg2.leave(@server, pid) end, :pg2.get_members(@server))
  end

  def add_node(name) do
    :pg2.join(@server, spawn(name, fn -> KVS.new_node() end))
  end

  def remove_node(name) do
    pid = :ets.lookup_element(:nodes, name, 2)
    :ets.delete(:ring, name)
    Kernel.send(pid, {self(), :remove})
    receive do
      {^pid, :transferred} -> :pg2.leave(@server, pid)
    end
  end

  def new_node() do
    :ets.insert(:nodes, {whoami(), self()})
    {tokens, node_to_tokens} = KVS.HashRing.steal_tokens()
    node_to_tokens |> Enum.map(fn {x, y} -> send(x, {:steal_tokens, y})end)
    # collect data
    data = Map.keys(node_to_tokens) |> Enum.map(fn x ->
      receive do
        {^x, m} -> m
      end
    end)
    |> List.flatten()
    |> Map.new()

    # update ring
    tokens
    |> Enum.map(fn x ->
      :ets.update_element(:ring, x, {2, whoami()})
    end)

    store(KVS.Node.new(data, tokens))
  end

  @spec store(%KVS.Node{}) :: no_return()
  def store(node) do
    receive do
      {sender, {:get, key}} ->
        preference_list = KVS.HashRing.lookup(key)
        :lists.foreach(fn pid -> send(pid, {:retrieve, sender, key}) end, preference_list)
        store(KVS.Node.add_read(node, {sender, key}))

      {sender, {:retrieve, client, key}} ->
        send(sender, {:retrieved, client, key, KVS.Node.get(node, key)})
        store(node)

      {sender, {:retrieved, client, key, object}} ->
        case KVS.Node.drop_read(node, {client, key}, object) do
          {:ok, objects, node} -> send(client, objects)
            store(node)
          node -> store(node)
        end

      {sender, {:put, key, object}} ->
        timestamp = now()
        preference_list = KVS.HashRing.lookup(key)
        me = whoami()
        if me in preference_list do
          :lists.foreach(fn pid -> send(pid, {:update, sender, key, {object, {timestamp, me}}}) end, preference_list)
          store(KVS.Node.add_write(node, {sender, key}))
        else
         send(hd(preference_list), {:redirect, preference_list, sender, key, object})
         store(node)
        end

      {sender, {:redirect, preference_list, client, key, object}} ->
        timestamp = now()
        :lists.foreach(fn pid -> send(pid, {:update, client, key, {object, {timestamp, whoami()}}}) end, preference_list)
        store(KVS.Node.add_write(node, {client, key}))


      {sender, {:update, client, key, object}} ->
        node = KVS.Node.put(node, key, object)
        send(sender, {:updated, client, key})
        store(node)

      {sender, {:updated, client, key}} ->
        case KVS.Node.drop_write(node, {client, key}) do
          {:ok, node} ->
            send(client, {self(), :ok})
            store(node)
          node ->
            store(node)
        end

      {sender, {:steal_tokens, tokens}} ->
        {node, data} = KVS.Node.drop_tokens(node, tokens)
        send(sender, data)
        store(node)

      {sender, :remove} ->
        others = :pg2.get_members(@server) -- [self()]
        transfer_map = KVS.Node.transfer_data(node, others)
        IO.inspect(transfer_map)
        transfer_map
        |> Enum.map(fn {other, data} ->
          Kernel.send(other, {self(), {:transfer, sender, data}})
        end)
        store(%{node| pending_t: Map.keys(transfer_map)})

      {sender, {:transfer, server, data}} ->
        node = KVS.Node.add_data(node, data)
        Kernel.send(sender, {self(), {:transferred, server}})
        store(node)

      {sender, {:transferred, server}} ->
        case node.pending_t do
          [sender] -> Kernel.send(server, {self(), :transferred})
          _ ->
            store(%{node|pending_t: List.delete(node.pending_t, sender)})
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
        send(sender, {self(), {node.data, node.tokens}})
        store(node)

      {sender, :download_data} ->
        send(sender, {self(), node.data})
        store(node)

      {sender, :download_token} ->
        send(sender, {self(), node.tokens})
        store(node)

      {sender, {:token_to_data, token}} ->
        send(sender, {self(), KVS.Node.token_to_data(node, token)})
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
