defmodule MembershipTest do
  use ExUnit.Case
  doctest KVS

  test "init_membership" do
    m = KVS.HashRing.new()
    IO.inspect(m)
    KVS.HashRing.lookup('elixir')
  end


  test "ets" do
    :ets.new(:ring, [:named_table, :ordered_set, :protected])
    :ets.insert(:ring, {0, 1})
    :ets.insert(:ring, {3,4})
  end
end