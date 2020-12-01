defmodule RingTest do
  use ExUnit.Case
  doctest Dynamo
  test "add_new_node" do
    ring = Dynamo.HashRing.new(:a)
    IO.puts("#{inspect(ring)}")
  end
end