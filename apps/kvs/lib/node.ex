defmodule KVS.Node do
  import Emulation, only: [send: 2, timer: 1, timer: 2, cancel_timer: 1, now: 0, whoami: 0]

  @n Application.fetch_env!(:kvs, :N)
  @writers Application.fetch_env!(:kvs, :writers)
  @readers Application.fetch_env!(:kvs, :readers)

  defstruct(
    data: nil,
    tokens: nil,
    pending_r: nil,
    pending_w: nil,
    pending_t: nil,
    merkle_tree_map: %{},
    partition_set_map: %{}
  )

  @spec new([any()]) :: %KVS.Node{}
  def new(tokens) do
    %KVS.Node{
    data: %{},
    tokens: tokens,
    pending_r: %{},
    pending_w: %{},
    pending_t: [],
    merkle_tree_map: %{},
    partition_set_map: %{}
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

  @spec put(%KVS.Node{}, any(), any(), any()):: %KVS.Node{}
  def put(node, key, context, object) do
    {writer, version} = context
    # adding key to partition_map_set
    node = KVS.Node.insert_key_to_tree(node, key)
    case get(node, key) do
      :error -> %{node|data: Map.put(node.data, key, {object, Map.new([context])})}
      {cur_object, vector} ->
        IO.puts("check obj")
        IO.inspect([cur_object,vector,writer])
      case Map.get(vector, writer, :error) do
        :error ->
          new_vector = Map.put(vector, writer, version)
          %{node|data: Map.put(node.data, key, {object, new_vector})}
        cur_version ->
          if cur_version > version do
            {:error, {cur_version, cur_object}}
          else
            new_vector = Map.put(vector, writer, version)
            %{node|data: Map.put(node.data, key, {object, new_vector})}
          end
      end
    end

  end

  def add_write(node, request, context, object) do
    {sender, key} = request
    case put(node, key, context, object) do
      {:error, info} -> {:error, info}
      node ->
        # IO.puts("after write")
        # IO.puts(whoami())
        # IO.inspect(Map.get(node.data, key, :error))
        {:ok, %{node|pending_w: Map.put(node.pending_w, {sender, key}, @writers-1)}}
    end
  end

  def drop_write(node, request) do
    IO.inspect(request)
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
    IO.puts("pending_R")
    IO.inspect(node.pending_r)
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
    node.data #{key, value}
    |> Enum.map(fn {x,y} -> [KVS.HashRing.hash(x), x, y] end)
    case :ets.prev(:ring, token) do
      '$end_of_table' -> :ets.last(:ring)
      other -> node.data
               |> Enum.filter(fn {key, value} ->
        hkey = KVS.HashRing.hash(key)
        hkey >= other and hkey < token end)
    end
  end

  #get one partiton end with token, return the a list of (key, obj)

  def get_single_partition_data_by_token(node, token) do
    case Map.get(node.partition_set_map, token, :error) do
      :error -> []
      partition_set ->
        Enum.reduce(partition_set, %{} ,fn x, acc -> Map.put(acc, x, Map.get(node.data, x, :error)) end)
    end
  end

  # def get_all_partition_data_before_token(node, token) do

  # end

  def insert_key_to_tree(node, key) do
    token = KVS.HashRing.key_end_hash(key)
    case Map.get(node.partition_set_map, token, :error) do
      # is it possible to get out of range token?
      :error ->
        %{node| partition_set_map: Map.put(node.partition_set_map, token, MapSet.new([key]))}
      partition_set ->
        %{node| partition_set_map: Map.put(node.partition_set_map, token, MapSet.put(partition_set, key))}
    end
  end


  @spec compare_node_with_merkle_tree(
          %{merkle_tree_map: map},
          atom | %{root: atom | %{key_hash: any}},
          any
        ) :: %{merkle_tree_map: map}
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
