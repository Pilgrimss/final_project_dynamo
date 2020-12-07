defmodule MembershipTest do
  use ExUnit.Case
  doctest KVS

  test "init_membership" do
    KVS.HashRing.new()
    KVS.HashRing.lookup('elixir')
  end



  test "ets" do
    :ets.new(:table, [:named_table, :ordered_set, :protected])
    :ets.insert(:table, {0, 1})
    :ets.insert(:table, {3, 4})
    IO.inspect(:ets.lookup_element(:table, 0, 2))
    IO.inspect(:ets.update_element(:table, 0, {2, 5}))
    IO.inspect(:ets.lookup_element(:table, 0, 2))
  end
end