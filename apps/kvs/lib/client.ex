defmodule KVS.Client do
  @timeout Application.fetch_env!(:kvs, :timeout)
  @server Application.fetch_env!(:kvs, :server)

  def get(key) do
    pid = :pg2.get_closest_pid(@server)
    send(pid, {self(), {:get, key}})
    receive do
      :error -> {:error, :key_not_exist}
      value -> value
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

end
