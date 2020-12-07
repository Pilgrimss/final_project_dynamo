defmodule KVS.Client do

  import Emulation, only: [now: 0]
#
#  import Kernel,
#         except: [spawn: 3, spawn: 1, spawn_link: 1, spawn_link: 3, send: 2]

#  import Fuzzers, only: [delay: 1, log_messages: 0]

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
    pros |> Enum.map(fn x ->
      receive do
        {^x, data} -> data
      after
        @timeout -> {:error, :timeout}
      end
    end)
  end

  def collect_data() do
    pros = :pg2.get_members(@server)
    pros |> Enum.map(fn x -> send(x, {self(), :download_data}) end)
    pros |> Enum.map(fn x ->
      receive do
        {^x, data} -> data
      after
        @timeout -> {:error, :timeout}
      end
    end)
  end

  def collect_token() do
    pros = :pg2.get_members(@server)
    pros |> Enum.map(fn x -> send(x, {self(), :download_token}) end)
    pros |> Enum.map(fn x ->
      receive do
        {^x, data} -> data
      after
        @timeout -> {:error, :timeout}
      end
    end)
  end

  # test reconcile
  def get_servers() do
    :pg2.get_members(@server)
  end

end
