defmodule KVSTest do
  use ExUnit.Case
  doctest KVS

#  test "kvs client and pg2" do
#    Emulation.init()
#    KVS.start()
#    {:ok, [:error, :error]} = KVS.Client.get(:a)
#    :ok = KVS.Client.put(:a, 10)
##    IO.inspect(KVS.Client.get(:a))
#    :ok = KVS.Client.put(:b, 12)
#    KVS.Client.get(:b)
#    :ok = KVS.Client.put(:a, 15)
#    KVS.Client.get(:a)
##    IO.inspect(KVS.Client.collect())
#  after
#    Emulation.terminate()
#  end

#  test "add_node" do
#    Emulation.init()
#    KVS.start()
#    1..10
#    |> Enum.map(fn x -> KVS.Client.put(x, x+1) end)
##    KVS.Client.put(:a, 1)
##    KVS.Client.put(:b, 2)
##    KVS.Client.put(:c, 3)
##    KVS.Client.put(:d, 4)
#    IO.inspect(KVS.Client.collect_token())
#    KVS.add_node(:test)
#    :timer.sleep(2000)
#    IO.inspect(KVS.Client.collect_token())
#    IO.inspect(KVS.Client.get(1))
#  after
#    Emulation.terminate()
#  end

  test "remove_node" do
    Emulation.init()
    KVS.start()
    1..10
    |> Enum.map(fn x -> KVS.Client.put(x, x+1) end)
    #    KVS.Client.put(:a, 1)
    #    KVS.Client.put(:b, 2)
    #    KVS.Client.put(:c, 3)
    #    KVS.Client.put(:d, 4)
    IO.inspect(KVS.Client.collect_token())
    KVS.remove_node(:a)
    :timer.sleep(2000)
    IO.inspect(KVS.Client.collect_token())
    IO.inspect(KVS.Client.get(1))
  after
    Emulation.terminate()
  end

#  test 'sleep' do
#    IO.puts 'foo'
#    :timer.sleep(2000)
#    IO.puts 'bar'
#  end

#  test "token_to_data" do
#    Emulation.init()
#    KVS.start()
#    KVS.Client.put(:a, 1)
#    KVS.Client.put(:b, 2)
#    KVS.Client.put(:c, 3)
#    KVS.Client.put(:d, 4)
#    IO.inspect(KVS.Client.collect_data())
#  after
#    Emulation.terminate()
#  end

#  test "hash ring " do
#    KVS.HashRing.new()
#    KVS.HashRing.lookup("test")
#    KVS.HashRing.lookup("sssssss")
#  end

#  test "iterate map" do
#    map = %{
#    a: [1,2],
#    b: [3,4],
#    c: [5,6]
#    }
#    |> Enum.map(fn {x,y} -> y end)
#  end

end
