defmodule KVS do
  @moduledoc """
  Documentation for `KVS`.
  """
  @server Application.fetch_env!(:kvs, :server)
  @nodes Application.fetch_env!(:kvs, :nodes)

  def start() do
    :pg2.create(@server)
    :lists.foreach(fn _ -> :pg2.join(@server, spawn(@server, :store, [%{}])) end, :lists.seq(0, @nodes))
  end

  def stop() do
    :lists.foreach(fn pid -> :pg2.leave(@server, pid) end, :pg2.get_members(@server))
  end

  def store(data) do
    receive do
      {sender, {:get, key}} ->
        IO.puts("Receive get request")
        IO.puts("#{inspect(data)}")
        send(sender, Map.fetch(data, key))
        store(data)
      {sender, {:put, key, object}} ->
        :lists.foreach(fn pid -> send(pid, {self(), {:update, key, object}}) end, :pg2.get_members(@server))
        send(sender, {self(), :ok})
        store(data)
      {_, {:update, key, object}} ->
        store(Map.put(data, key, object))
    end
  end
end
