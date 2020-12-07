defmodule VersionTest do
  use ExUnit.Case
  doctest KVS
  test 'client context' do
    Emulation.init()
    KVS.start()
    {:ok, [:error]} = KVS.Client.get(:a)
    :ok = KVS.Client.put(:a, 1, 10)
        IO.inspect(KVS.Client.get(:a))
    :ok = KVS.Client.put(:b, 1, 12)
    KVS.Client.get(:b)
    :ok = KVS.Client.put(:a, 1, 15)
    KVS.Client.get(:a)
    |> IO.inspect()
    #    IO.inspect(KVS.Client.collect())
  after
    Emulation.terminate()
  end

end