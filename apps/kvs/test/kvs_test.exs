defmodule KVSTest do
  use ExUnit.Case
  doctest KVS

  test "kvs client and pg2" do
    Emulation.init()
    KVS.start()
    {:ok, [:error, :error]} = KVS.Client.get(:a)
    :ok = KVS.Client.put(:a, 10)
    IO.inspect(KVS.Client.get(:a))
    :ok = KVS.Client.put(:b, 12)
    KVS.Client.get(:b)
    :ok = KVS.Client.put(:a, 15)
    KVS.Client.get(:a)
    IO.inspect(KVS.Client.collect())
  after
    Emulation.terminate()
  end

#  test "hash ring " do
#    KVS.HashRing.new()
#    IO.inspect(KVS.HashRing.lookup("test"))
#    IO.inspect(KVS.HashRing.lookup("sssssss"))
#  end

end
