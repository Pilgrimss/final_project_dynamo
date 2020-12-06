defmodule MembershipTest do
  use ExUnit.Case
  doctest KVS

  test "init_membership" do
    KVS.HashRing.new()
    KVS.HashRing.lookup('elixir')
  end



  test "ets" do
    :ets.new(:ring, [:named_table, :ordered_set, :protected])
    :ets.insert(:ring, {0, 1})
    :ets.insert(:ring, {3, 4})
    IO.inspect(:ets.lookup_element(:ring, 0, 2))
    IO.inspect(:ets.update_element(:ring, 0, {2, 3}))
    IO.inspect(:ets.lookup_element(:ring, 0, 2))
  end
end