defmodule AuthEx do

  @abilities [
    {[:index, :show], User, []}
  ]
  def load_resource!(conn) do

  end

  def authorize!(conn, resource) do
  end
end
