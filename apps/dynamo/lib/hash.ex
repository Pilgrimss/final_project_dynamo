defmodule Dynamo.Hash do
  defp hash(key) do
    Base.encode16(:crypto.hash(:md5, key))
  end
end