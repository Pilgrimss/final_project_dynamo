defmodule BenchmarkTest do
  use ExUnit.Case
  doctest KVS

  def t_test(time) do
    1..1000
    |> Enum.map(fn x -> KVS.Client.put_and_get(x, 1, x+1, time) end)
    |> Enum.filter(fn x -> x == true end)
    |> length()
  end

  def test_with_time(time) do
    res = 1..10
    |> Enum.map(fn _ -> t_test(time)/1000 end)
    Enum.sum(res)/length(res)
  end

  test 'PBS t-visibility' do
    Emulation.init()
    KVS.start()
    0..30
    |> Enum.map(fn x -> [x, test_with_time(0)]end)
    |> IO.inspect()
  after
    Emulation.terminate()
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