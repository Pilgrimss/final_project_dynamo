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
        :lists.foreach(fn pid -> send(pid, {self(), {:retrieve, sender, key}}) end,:pg2.get_members(@server))
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
        :lists.foreach(fn pid -> send(pid, {self(), {:update, sender, key, object}}) end, :pg2.get_members(@server))
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
    end
  end
end
