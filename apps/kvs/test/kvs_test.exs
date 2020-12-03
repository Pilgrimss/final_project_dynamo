defmodule KVSTest do
  use ExUnit.Case
  doctest KVS

  test "kvs client and pg2" do
    KVS.start()

IO.inspect(KVS.Client.get(:a))
    :ok = KVS.Client.put(:a, 10)
    {:ok, [10, 10]} = KVS.Client.get(:a)
    :ok = KVS.Client.put(:b, 12)
    {:ok, [12, 12]} = KVS.Client.get(:b)
  end
end
