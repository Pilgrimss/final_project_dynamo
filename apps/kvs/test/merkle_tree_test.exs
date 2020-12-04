defmodule MerkleTreeTest do
  use ExUnit.Case
  doctest KVS
  test "merkle tree using self hash" do
    test1 = [{"zebra", 0}, {"daisy", 0}]
    test2 = [{"java", 0}, {"ada", 0}]
    m1 = Merkel.new(test1)
    m2 = Merkel.new(test2)
    assert m1 != m2
  end

  test "merkle tree order not matter" do
    test1 = []
    test2 = []
    m1 = Merkel.new(test1)
    m2 = Merkel.new(test2)
    m1 = Merkel.insert(m1, {"ada", 1})
    m1 = Merkel.insert(m1, {"java", 2})
    m1 = Merkel.insert(m1, {"python", 2})
    m2 = Merkel.insert(m2, {"java", 1})
    m2 = Merkel.insert(m2, {"ada1", 2})
    m2 = Merkel.insert(m2, {"python", 2})


    assert m1.root.right.key_hash == m2.root.right.key_hash
    # IO.inspect(m1.root.key)
    # assert m1.root.left.key_hash == m2.root.left.key_hash
    # assert m1.root == m2.root
    # assert m1.root.left.key_hash == m2.root.left.key_hash
    # assert m1.root.right.right.key_hash == m2.root.right.right.key_hash

  end

  test "merkle tree get leaves from root" do
    test1 = []
    m1 = Merkel.new(test1)
    m1 = Merkel.insert(m1, {"ada", 1})
    m1 = Merkel.insert(m1, {"java", 2})
    m1 = Merkel.insert(m1, {"python", 2})
    m1 = Merkel.insert(m1, {"php", 2})
    m1 = Merkel.insert(m1, {"elixir", 2})

    assert ["ada", "elixir", "java", "php", "python"] == KVS.Node.get_all_leaves_from_root(m1.root, [])
    assert ["ada","elixir","java"] == KVS.Node.get_all_leaves_from_root(m1.root.left, [])
    assert [ "php", "python"] == KVS.Node.get_all_leaves_from_root(m1.root.right, [])
  end

  test "compute dif list from two merkel tree" do
    test1 = [{"ada",0}, {"elixir",0}, {"java",0}, {"php",0}, {"python",0}]
    test2 = []
    m1 = Merkel.new(test1)
    my_tree = Merkel.new(test2)
    m1 = Merkel.insert(m1, {"ada", 1})
    m1 = Merkel.insert(m1, {"java", 2})
    m1 = Merkel.insert(m1, {"python", 2})
    m1 = Merkel.insert(m1, {"php", 2})
    m1 = Merkel.insert(m1, {"elixir", 2})
    # Merkel.print(m1)

    # assert {:need_add, ["ada", "elixir", "java", "php", "python"]} == KVS.Node.compare_merkle_tree(my_tree.root,m1.root,[])
    my_tree = Merkel.insert(my_tree, {"ada", 1})

    assert {:need_add, ["elixir", "java", "php", "python"]} == KVS.Node.compare_merkle_tree(my_tree.root,m1.root,[])


    my_tree = Merkel.insert(my_tree, {"java", 2})
    assert {:need_add, [ "elixir", "php", "python"]} == KVS.Node.compare_merkle_tree(my_tree.root,m1.root,[])
    my_tree = Merkel.insert(my_tree,{"elixir",2})
    assert {:need_add, ["php", "python"]} == KVS.Node.compare_merkle_tree(my_tree.root,m1.root,[])
    my_tree = Merkel.insert(my_tree, {"php", 2})
    assert {:need_add, ["python"]} == KVS.Node.compare_merkle_tree(my_tree.root,m1.root,[])
    my_tree = Merkel.insert(my_tree, {"php2", 2})
    assert {:need_add, ["python"]} == KVS.Node.compare_merkle_tree(my_tree.root,m1.root,[])
    my_tree = Merkel.insert(my_tree, {"python", 2})
    assert {:need_add, []} == KVS.Node.compare_merkle_tree(my_tree.root,m1.root,[])
    {:ok, my_tree} = Merkel.delete(my_tree, "php2")
    assert Merkel.keys(my_tree) == Merkel.keys(m1)
    Merkel.print(my_tree)
    Merkel.print(m1)
    assert my_tree.root.key_hash == m1.root.key_hash

    assert {:ok, []} == KVS.Node.compare_merkle_tree(my_tree.root,m1.root,[])

  end
end
