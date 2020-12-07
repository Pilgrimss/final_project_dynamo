defmodule KVS.Node do

  @n Application.fetch_env!(:kvs, :N)
  @writers Application.fetch_env!(:kvs, :writers)
  @readers Application.fetch_env!(:kvs, :readers)

  defstruct(
    data: nil,
    tokens: nil,
    pending_r: nil,
    pending_w: nil,
    pending_t: nil,
    merkle_tree_map: %{}
  )

  @spec new([any()]) :: %KVS.Node{}
  def new(tokens) do
    %KVS.Node{
    data: %{},
    tokens: tokens,
    pending_r: %{},
    pending_w: %{},
    pending_t: [],
    merkle_tree_map: %{}
    }
  end

  @spec new(%{},[any()]) :: %KVS.Node{}
  def new(data, tokens) do
    %KVS.Node{
      data: data,
      tokens: tokens,
      pending_r: %{},
      pending_w: %{},
      pending_t: [],
      merkle_tree_map: %{}
    }
  end

  @spec get(%KVS.Node{}, any()) :: any()
  def get(node, key) do
    Map.get(node.data, key, :error)
  end

  @spec put(%KVS.Node{}, any(), any()):: %KVS.Node{}
  def put(node, key, object) do
    %{node|data: Map.put(node.data, key, object)}
  end

  def add_write(node, request) do
    %{node|pending_w: Map.put(node.pending_w,request, @writers)}
  end

  def drop_write(node, request) do
    case Map.get(node.pending_w, request, :error) do
      :error -> node
      1 -> {:ok, %{node| pending_w: Map.delete(node.pending_w, request)}}
      count -> %{node| pending_w: Map.put(node.pending_w, request, count-1)}
    end
  end

  def add_read(node, request) do
    %{node|pending_r: Map.put(node.pending_r, request, {@readers, []})}
  end

  def drop_read(node, request, object) do
    case Map.get(node.pending_r, request, :error) do
      :error -> node
      {1, objects} ->
        node = %{node| pending_r: Map.delete(node.pending_r,request)}
        {:ok, [object|objects], node}
      {count, objects} ->
        %{node| pending_r: Map.put(node.pending_r, request, {count-1, [object|objects]})}
    end
  end

  def transfer_data(node, others) do
    get_data(node)
    |> Enum.map(fn {token, data} ->
      [Enum.random(others), {token, Map.new(data)}]
    end)
    |> List.foldl(%{}, fn [node, data], acc -> Map.update(acc, node, [data], fn acc_data -> [data|acc_data] end)  end)
  end

  def add_data(node, data) do
    node = data
    |> List.foldr(node, fn {token, data}, acc ->
    %{acc|tokens: [token|acc.tokens], data: Map.merge(data, acc.data)
    }
    end)
  end

  def get_data(node) do
    data = node.tokens
    |> Enum.map(fn token -> {token, token_to_data(node, token)}  end)
  end

  def drop_tokens(node, tokens) do
    case tokens do
      nil -> {node, []}
      _ -> data = tokens
           |> Enum.map(fn token -> token_to_data(node, token) end)
           |> List.flatten()
           node = %{node| tokens: node.tokens--tokens}
           {node, data}
    end
  end

  def token_to_data(node, token) do
    node.data
    |> Enum.map(fn {x,y} -> [KVS.HashRing.hash(x), x, y] end)
    case :ets.prev(:ring, token) do
      '$end_of_table' -> :ets.last(:ring)
      other -> node.data
               |> Enum.filter(fn {key, value} ->
        hkey = KVS.HashRing.hash(key)
        hkey >= other and hkey < token end)
    end
  end

  def compare_node_with_merkle_tree(node, tree, tree_range) do
    #todo
      {_, list} = compare_merkle_tree(node.merkle_tree_map[tree_range].root, tree.root,[])
      node = insert_keys(node, list, tree_range)
      node
  end

  # elementary level compare, only speed up if two tree are equal
  def compare_merkle_tree(my_root, other_root, res_list) do
    cond do
      my_root.key_hash == other_root.key_hash ->
        {:ok, []}
      true ->
        my_list = get_all_leaves_from_root(my_root)
        other_list = get_all_leaves_from_root(other_root)
        res = other_list -- my_list
        {:need_add, res}
    end
  end
  # abandoned function, merkle tree might need to be exchanged by send hashes
  # def compare_merkle_tree(my_root, other_root, res_list) do
  #   cond do
  #     my_root == nil  ->
  #       list = get_all_leaves_from_root(other_root)
  #       {:need_add, res_list ++ list}

  #     my_root.key_hash == other_root.key_hash ->
  #       {:ok, []}

  #     true ->
  #      {_, left} = compare_merkle_tree(my_root.left, other_root.left, res_list)
  #      {_, right} = compare_merkle_tree(my_root.right, other_root.right, res_list)
  #       res_list = res_list ++ left ++ right
  #       {:need_add, res_list}
  #   end
  # end

  def get_all_leaves_from_root(root) do
    get_all_leaves_from_root(root, [])
  end

  def get_all_leaves_from_root(root, list) do
    cond do
      root == nil ->
      []
      root.key != nil ->
      list = list ++ [root.key]
      list
      true ->
      left = get_all_leaves_from_root(root.left, [])
      right = get_all_leaves_from_root(root.right, [])
      list = left ++ right
      list
    end
  end
  def insert_keys(node, list, tree_range) do
    t = []
    tree = Map.get(node.merkle_tree_map, tree_range, Merkel.new(t))
    tree = list |> Enum.reduce(tree, fn x, tree -> Merkel.insert(tree, {x, 0}) end)
    node= %{node | merkle_tree_map: Map.put(node.merkle_tree_map, tree_range, tree)}
    node
  end


end
