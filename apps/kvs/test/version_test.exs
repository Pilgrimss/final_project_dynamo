defmodule VersionTest do
  use ExUnit.Case
  doctest KVS
  test 'client context' do
    Emulation.init()
    KVS.start()
    {:ok, [:error]} = KVS.Client.get(1)
    :ok = KVS.Client.put(1, 1, 10)
    IO.inspect(KVS.Client.get(1))
#    :ok = KVS.Client.put(2, 1, 12)
#    KVS.Client.get(2)
    :ok = KVS.Client.put(1, 4, 15)
#    IO.inspect(KVS.Client.get(1))
#        IO.inspect(KVS.Client.collect())
  after
    Emulation.terminate()
  end

end