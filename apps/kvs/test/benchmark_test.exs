defmodule BenchmarkTest do
  use ExUnit.Case
  doctest KVS

  def t_test(time) do
    pass =
    1..1000
    |> Enum.map(fn x -> KVS.Client.put_and_get(x, 1, x+1, time) end)
    |> Enum.filter(fn x -> x == true end)
    |> length()
    pass/1000
  end


  test 'PBS t-visibility' do
    Emulation.init()
    Emulation.append_fuzzers([Fuzzers.delay(20)])
    KVS.start()
    3..3
    |> Enum.map(fn x -> [x, t_test(x)]end)
    |> IO.inspect()
  after
    Emulation.terminate()
  end

  def put_then_get() do
    1..100
    |> Enum.map(fn x -> KVS.Client.put(x, 1, x+1) end)


  end


#  test "one reader" do
#    Emulation.init()
#    KVS.start()
#    :error = KVS.Client.get(1)
#  after
#    Emulation.terminate()
#  end
#
#  test "one writer" do
#    Emulation.init()
#    KVS.start()
#    1..10
#    |> Enum.map(fn x -> KVS.Client.put(x, 1, x+1) end)
#    |> IO.inspect()
#  end
end