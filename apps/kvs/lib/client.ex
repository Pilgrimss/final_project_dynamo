defmodule KVS.Client do
  @timeout Application.fetch_env!(:kvs, :timeout)
  @server Application.fetch_env!(:kvs, :server)

  def get(key) do
    pid = :pg2.get_closest_pid(@server)
    send(pid, {self(), {:get, key}})
    receive do
      :error -> {:error, :key_not_exist}
      object -> {:ok, object}
    after
        @timeout -> {:error, :timeout}
    end
  end

  def put(key, object) do
    pid = :pg2.get_closest_pid(@server)
    send(pid, {self(), {:put, key, object}})
    receive do
      {_, :ok} -> :ok
    after
      @timeout -> {:error, :timeout}
    end
  end

  # test function
  def collect() do
    pros = :pg2.get_members(@server)
    pros |> Enum.map(fn x -> send(x, {self(), :download}) end)
    data = pros
    |> Enum.map(fn x ->
      receive do
        {^x, data} -> data
      end
    end)
  end

  # test reconcile
  def get_servers() do
    :pg2.get_members(@server)
  end

end